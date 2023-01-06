#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import JXKit
import FairCore

/// Script loader that attempts to locate source files for loaded JavaScript and monitor those files for changes.
public class MonitoringScriptLoader: JXScriptLoader {
    private lazy var locator = SourceFileLocator()
    private var sourceURLs: [URL: URL] = [:]
    private var updatedURLs: Set<URL> = []
    private var dispatchSources: [URL: DispatchSourceFileSystemObject] = [:]
    private var updateScheduled = false
    private let log: (String) -> Void

    /// Create a monitoring script loader.
    ///
    /// - Parameters:
    ///   - updateInterval: The interval at which updates are sent after a change is detected.
    ///   - log: The logging function to use for log messages. Defaults to using `print`.
    public init(updateInterval: TimeInterval = 0.2, log: @escaping (String) -> Void = { dbg($0) }) {
        self.updateInterval = updateInterval
        self.log = log
    }

    deinit {
        dispatchSources.values.forEach { $0.cancel() }
    }

    /// The interval at which updates are sent after a change is detected. Defaults to 0.2 seconds.
    public var updateInterval: TimeInterval

    /// The set of root source directories to search for `.js` source files corresponding to loaded resources.
    public var sourceDirectories: [URL] {
        get {
            return locator.sourceDirectories
        }
        set {
            locator.sourceDirectories = newValue
        }
    }

    public let didChange: JXListenerCollection<(Set<URL>) -> Void>? = JXListenerCollection<(Set<URL>) -> Void>()

    public func loadScript(from url: URL) throws -> String? {
        if let sourceURL = sourceURLs[url] {
            return try String(contentsOf: sourceURL)
        }

        // The first time we see a URL, use default loading to get the actual scriptURL, which
        // we then use to look for the source. We cache resolved source URLs for subsequent lookups
        let (scriptURL, script) = try defaultLoadScript(from: url)
        guard let sourceURL = locator.sourceFile(for: scriptURL) else {
            return script
        }

        sourceURLs[url] = sourceURL
        monitor(url: sourceURL, sendingUpdateOf: url)
        dbg("loading JavaScript at \(sourceURL)")
        return sourceURL == scriptURL ? script : try String(contentsOf: sourceURL)
    }

    @discardableResult private func monitor(url: URL, sendingUpdateOf updateURL: URL, isUpdated: Bool = false) -> Bool {
        guard url.isFileURL, !dispatchSources.keys.contains(url) else {
            return false
        }

        let path = url.absoluteURL.path
        let handle = open(path, O_EVTONLY)
        guard handle != -1 else {
            dbg("Unable to monitor JavaScript at \(url)")
            return false
        }

        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: handle, eventMask: [.write, .extend, .delete, .rename], queue: DispatchQueue.main)
        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else {
                return
            }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                // Editors tend to delete and then re-write the file
                self.stopMonitoring(url: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.updateInterval / 2.0) { [weak self] in
                    self?.monitor(url: url, sendingUpdateOf: updateURL, isUpdated: true)
                }
            } else {
                self.scheduleUpdate(url: updateURL)
            }
        }
        source.setCancelHandler {
            close(handle)
        }
        dispatchSources[url] = source
        source.resume()
        if isUpdated {
            scheduleUpdate(url: updateURL)
        }
        return true
    }

    private func stopMonitoring(url: URL) {
        dispatchSources.removeValue(forKey: url)?.cancel()
    }

    private func scheduleUpdate(url: URL) {
        guard updatedURLs.insert(url).inserted else {
            return
        }
        guard !updateScheduled else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + updateInterval) { [weak self] in
            self?.updateScheduled = false
            self?.performUpdate()
        }
    }

    private func performUpdate() {
        let urls = updatedURLs
        updatedURLs.removeAll()
        didChange?.forEach { $0(urls) }
    }
}

/// Helper class to find the JavaScript source files corresponding to bundle resources.
///
/// The developer can set a `JXSOURCEPATH` environment variable in their scheme to a `:`-separated list of directories to search for JavaScript sources.
/// Otherwise, we attempt to determine the project or workspace root.
private class SourceFileLocator {
    init() {
        let env = ProcessInfo.processInfo.environment
        if let sourceDirectories = env["JXSOURCEPATH"]?.split(separator: ":").map({ URL(fileURLWithPath: String($0), isDirectory: true) }) {
            self.sourceDirectories = sourceDirectories
            dbg("javaScript dynamic reload source path: \(sourceDirectories)")
        } else if let projectDirectory = Self.findProjectDirectory(env) {
            dbg("javaScript dynamic reload source path: \(projectDirectory)")
            self.sourceDirectories = [projectDirectory]
        } else {
            self.sourceDirectories = []
        }
    }

    var sourceDirectories: [URL] {
        didSet {
            if sourceDirectories != oldValue {
                _allSourceDirectoryFiles = nil
                _siblingDirectoryFiles = [:]
            }
        }
    }

    func sourceFile(for url: URL) -> URL? {
        guard url.isFileURL else {
            return nil
        }
        guard !sourceDirectories.isEmpty else {
            return url
        }
        guard url.pathExtension == "js" else {
            dbg("WARNING: JavaScript file \(url) should have a .js extension for dynamic reload support")
            return url
        }

        // We expect bundle URLs for resources at runtime. Find the last component ending in .bundle (for bundles and SPM packages)
        // or .app (for the application main bundle) and try to match on the subsequent file path
        let components = url.pathComponents
        for e in components.enumerated().reversed() {
            if e.element.hasSuffix(".bundle") {
                guard e.offset < components.count - 1 else {
                    return nil
                }
                let relativePath = components[e.offset + 1..<components.count].joined(separator: "/")
                return sourceFile(bundle: String(e.element.dropLast(".bundle".count)), path: relativePath) ?? url
            } else if e.element.hasSuffix(".app") {
                guard e.offset < components.count - 1 else {
                    return nil
                }
                let relativePath = components[e.offset + 1..<components.count].joined(separator: "/")
                return sourceFile(app: String(e.element.dropLast(".app".count)), path: relativePath) ?? url
            }
        }
        return url
    }

    private func sourceFile(bundle: String, path: String) -> URL? {
        var directory = bundle
        // Is this a SPM package bundle? We're assuming that any '_'-separated name is a SPM bundle
        let packageInfo = bundle.split(separator: "_")
        if packageInfo.count == 2 {
            directory = String(packageInfo[0])
        }
        return findSourceFile(path: path, preferredDirectory: directory, searchSiblingDirectories: true)
    }

    private func sourceFile(app: String, path: String) -> URL? {
        return findSourceFile(path: path, preferredDirectory: app, searchSiblingDirectories: false)
    }

    private func findSourceFile(path: String, preferredDirectory: String, searchSiblingDirectories: Bool) -> URL? {
        // Look for any source files matching the given path
        let findPath = "/" + path
        let findDirectoryPrefix = preferredDirectory + "/"
        let findDirectory = "/" + findDirectoryPrefix
        var pathMatch: URL? = nil
        for sourceFile in allSourceDirectoryFiles {
            let sourcePath = sourceFile.path
            if sourcePath.hasSuffix(findPath) {
                // If we find a match below the preferred directory, return it immediately.
                // Otherwise hold out for a possible better match
                if sourcePath.hasPrefix(findDirectoryPrefix) || sourcePath.contains(findDirectory) {
                    return sourceFile
                } else {
                    pathMatch = sourceFile
                }
            }
        }

        // We didn't find a match in the preferred directory. Is there a sibling directory match?
        // We search sibling directories for scenarios where a project depends on sibling packages
        guard searchSiblingDirectories else {
            return pathMatch
        }
        for sourceFile in siblingDirectoryFiles(for: preferredDirectory) {
            if sourceFile.path.hasSuffix(findPath) {
                return sourceFile
            }
        }
        return pathMatch
    }

    private var allSourceDirectoryFiles: [URL] {
        if let files = _allSourceDirectoryFiles {
            return files
        }
        let files = Self.allSourceFiles(in: sourceDirectories)
        _allSourceDirectoryFiles = files
        return files
    }
    private var _allSourceDirectoryFiles: [URL]?

    private func siblingDirectoryFiles(for directory: String) -> [URL] {
        if let files = _siblingDirectoryFiles[directory] {
            return files
        }
        var siblingDirectories: [URL] = []
        for sourceDirectory in sourceDirectories {
            let siblingDirectory = sourceDirectory.deletingLastPathComponent().appendingPathComponent(directory, isDirectory: true)
            if FileManager.default.fileExists(atPath: siblingDirectory.path) {
                siblingDirectories.append(siblingDirectory)
            }
        }
        let files = Self.allSourceFiles(in: siblingDirectories)
        _siblingDirectoryFiles[directory] = files
        return files
    }
    private var _siblingDirectoryFiles: [String: [URL]] = [:]

    private static func allSourceFiles(in directories: [URL]) -> [URL] {
        var sourceFiles: [URL] = []
        for directory in directories {
            if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [], options: .skipsHiddenFiles) {
                for case let file as URL in enumerator {
                    if file.pathExtension == "js" {
                        sourceFiles.append(file)
                    }
                }
            }
        }
        return sourceFiles
    }

    private static func findProjectDirectory(_ env: [String: String]) -> URL? {
        // Use the DYLD_LIBRARY_PATH to read the project/workspace directory info.plist

        // 1. Get the user portion of the path
        // e.g. /Users/marc/Library/Developer/Xcode/DerivedData/App-eyahphpvsfdoezahxmpgdlrnhwxg/Build/Products/Debug-iphonesimulator
        guard let dyld = env["DYLD_LIBRARY_PATH"]?.split(separator: ":").first else {
            return nil
        }

        // 2. Read the generated info.plist to get the project/workspace path
        let dyldDir = URL(fileURLWithPath: String(dyld), isDirectory: true)
        let workspaceInfo = URL(fileURLWithPath: "../../../info.plist", isDirectory: false, relativeTo: dyldDir)
        do {
            let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: workspaceInfo), options: [], format: nil)
            guard let workspacePath = (plist as? NSDictionary)?["WorkspacePath"] as? String else {
                return nil
            }

            // 3. workspacePath will be something like: /opt/src/appfair/World-Fair/App.xcworkspace or .xcodeproj
            return URL(fileURLWithPath: workspacePath).deletingLastPathComponent()
        } catch {
            return nil
        }
    }
}
#endif // !os(Linux) && !os(Android) && !os(Windows)
