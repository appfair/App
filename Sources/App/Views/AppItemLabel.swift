/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import FairKit
import FairExpo

struct AppItemLabel : View {
    let item: AppInfo
    @EnvironmentObject var fairManager: FairManager

    var body: some View {
        label(for: item)
    }

    var installedVersion: String? {
        if item.isCask {
            return fairManager.homeBrewInv.appInstalled(item: item)
        } else {
            return fairManager.fairAppInv.appInstalled(item: item.app)
        }
    }

    private func label(for item: AppInfo) -> some View {
        return HStack(alignment: .center) {
            ZStack {
                fairManager.iconView(for: item, transition: true)

                if let progress = fairManager.operations[item.id]?.progress {
                    FairProgressView(progress)
                        .progressViewStyle(PieProgressViewStyle(lineWidth: 50))
                        .foregroundStyle(Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)) // make sure the progress doesn't extend pask the icon bounds
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(verbatim: item.app.name)
                        .font(.headline)
                        .lineLimit(1)
                    if fairManager.enableSponsorship,
                       let fundingLink = item.app.fundingLinks?.first {
//                        ProgressView(value: wip(0.5), total: wip(1.0))
//                            .progressViewStyle(.linear)
//                        FairSymbol.rosette.image
//                            .help(fundingLink.localizedTitle ?? "")
                    }
                }

                TintedLabel(title: Text(item.app.subtitle ?? item.app.name), symbol: (item.displayCategories.first ?? .utilities).symbol, tint: item.app.itemTintColor(), mode: .hierarchical)
                    .font(.subheadline)
                    .lineLimit(1)
                    .symbolVariant(.fill)
                //.help(category.text)
                HStack {
                    if item.app.permissions != nil {
                        item.app.riskLevel.riskLabel()
                            .help(item.app.riskLevel.riskSummaryText())
                            .labelStyle(.iconOnly)
                            .frame(width: 20)
                    }

                    if let catalogVersion = item.app.version {
                        Label {
                            if let installedVersion = self.installedVersion,
                               catalogVersion != installedVersion {
                                Text("\(installedVersion) (\(catalogVersion))", bundle: .module, comment: "formatting text for the app list version section displaying the installed version with the currently available version in parenthesis")
                                    .font(.subheadline)
                            } else {
                                Text(verbatim: catalogVersion)
                                    .font(.subheadline)
                            }
                        } icon: {
                            if let installedVersion = self.installedVersion {
                                if installedVersion == catalogVersion {
                                    CatalogActivity.launch.info.systemSymbol
                                        .foregroundStyle(CatalogActivity.launch.info.tintColor ?? .accentColor) // same as launchButton()
                                        .help(Text("The latest version of this app is installed", bundle: .module, comment: "tooltip text for the checkmark in the apps list indicating that the app is currently updated to the latest version"))
                                } else {
                                    CatalogActivity.update.info.systemSymbol
                                        .foregroundStyle(CatalogActivity.update.info.tintColor ?? .accentColor) // same as updateButton()
                                        .help(Text("An update to this app is available", bundle: .module, comment: "tooltip text for the checkmark in the apps list indicating that the app is currently installed but there is an update available"))
                                }
                            }
                        }
                    }

                    if let versionDate = item.app.versionDate {
                        Text(versionDate, format: .relative(presentation: .numeric, unitsStyle: .narrow))
                            //.refreshingEveryMinute()
                            .font(.subheadline)
                    }

                }
                .lineLimit(1)
            }
            .allowsTightening(true)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AppItemLabel_Previews: PreviewProvider {
    static var previews: some View {
        //let info = AppInfo(catalogMetadata: AppCatalogItem(name: "My App", bundleIdentifier: "app.My-App", downloadURL: appfairRoot))
        //let info = AppInfo(app: AppCatalogItem.sample)

        ForEach([ColorScheme.light, .dark], id: \.self) { colorScheme in
            Text(verbatim: "XXX")
            //AppItemLabel(item: info)
        }
    }
}
