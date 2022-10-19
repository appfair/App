import FairApp
import SQLEnclave

struct DiscoverView : View {
    @Query(StationsRequest(ordering: .byClickTrend)) private var stations: [Station]

    @EnvironmentObject var store: Store
    @State var nowPlayingTitle: String? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(stations, content: stationRowView)
            }
            .navigation(title: Text("Discover"), subtitle: Text("Stations"))
        }
    }

    func stationRowView(station: Station) -> some View {
        NavigationLink {
            StationView(station: station, itemTitle: $nowPlayingTitle)
                .environmentObject(RadioTuner.shared)
        } label: {
            //Text(station.name ?? "")
            Label(title: { stationLabelTitle(station) }) {
                station.iconView(size: 50)
                    .frame(width: 50)
            }
            .labelStyle(StationLabelStyle())

        }
    }
}
