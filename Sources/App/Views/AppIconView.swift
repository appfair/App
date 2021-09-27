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
import FairApp

@available(macOS 12.0, iOS 15.0, *)
struct AppIconView: View {
    var iconName: String
    var baseColor: Color

    var body: some View {
        GeometryReader { proxy in
            let span = min(proxy.size.width, proxy.size.height)
            ZStack(alignment: Alignment.center) {
                Circle()
                    .foregroundStyle(
                        .linearGradient(colors: [Color.gray, .white], startPoint: .bottomLeading, endPoint: .topTrailing))

                Circle()
                    .inset(by: span / 20)
                    .foregroundStyle(
                        .linearGradient(colors: [Color.gray, .white], startPoint: .topTrailing, endPoint: .bottomLeading))

//                Text("X", bundle: .module)
//                    .font(Font.system(size: span / 2, weight: .bold, design: .rounded))
//                    .foregroundColor(.red)


                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.linearGradient(colors: [baseColor, baseColor.opacity(0.5)], startPoint: .topTrailing, endPoint: .bottomLeading))
                    //.border(.black, width: 1)
                    //.padding(span / 8)
                    //.background(Color.white.clipShape(Circle()))
                    //.padding(span / 30)
                    .shadow(color: .black, radius: 0, x: -span / 200, y: span / 200)
                    //.clipShape(Circle())
                    .frame(width: span * 0.5, height: span * 0.5)
            }
        }
        //.overlay(Text("X").font(Font.system(size: 70, weight: .bold, design: .rounded)))
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([16.0, 32.0, 128.0, 256.0, 512.0], id: \.self) { span in
            AppIconView(iconName: "sparkle", baseColor: Color.randomIconColor())
                .frame(width: span, height: span)
        }
    }
}

extension Color {
    static func randomIconColor(first: Bool = true) -> Self {
        Color.accentColor
        // Color(hue: Double.random(in: 0...1), saturation: 0.99, brightness: 0.99)
    }
}
