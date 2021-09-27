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

struct ActionButtonStyle: ButtonStyle {
    var primary: Bool
    var highlighted: Bool

    private struct ActionButton: View {
        @Environment(\.isEnabled) var isEnabled

        var defaultColor: Color = Color.white
        var highlightColor: Color = Color.accentColor
        var disabledColor: Color = Color.secondary

        var configuration: ButtonStyle.Configuration
        var primary: Bool
        var highlighted: Bool

        var body: some View {
            configuration.label
                .font(Font.caption.weight(.bold))
                .foregroundColor(internalColor)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .frame(minWidth: 65)
                .background(background(isPressed: configuration.isPressed))
                .padding(1)
        }

        var internalColor: Color {
            isEnabled ? (primary ? (highlighted ? highlightColor : defaultColor) : highlightColor) : (primary ? (highlighted ? disabledColor : defaultColor)  : (highlighted ? defaultColor : disabledColor))
        }

        func background(isPressed: Bool) -> some View {
            Group {
                if isEnabled {
                    if primary {
                        Capsule().fill(highlighted ? defaultColor : highlightColor)
                    } else {
                        Capsule().fill(Color(UXColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)))
                    }
                } else {
                    if primary {
                        Capsule().fill(highlighted ? defaultColor : disabledColor)
                    } else {
                        EmptyView()
                    }
                }
            }
            .brightness(isPressed ? -0.25 : 0)
        }
    }

    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        ActionButton(configuration: configuration, primary: primary, highlighted: highlighted)
    }
}

struct ActionButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach([ColorScheme.light, .dark], id: \.self) { colorScheme in
                Group {
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(primary: true, highlighted: false))
                        .padding()
                        //.background(Color(UXColor.textBackgroundColor))
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(primary: true, highlighted: true))
                        .padding()
                        //.background(Color(.controlAccentColor))
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(primary: true, highlighted: false))
                        .padding()
                        .disabled(true)
                        //.background(Color(UXColor.textBackgroundColor))
                }
                .colorScheme(colorScheme)
                .preferredColorScheme(colorScheme)
            }
        }
    }
}
