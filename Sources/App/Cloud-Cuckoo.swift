import FairApp

extension View {
    /// Install a hover action on platforms that support it
    func whenHovering(perform action: @escaping (Bool) -> ()) -> some View {
        #if os(macOS) || os(iOS)
        return self.onHover(perform: action)
        #else
        return self
        #endif
    }
}

