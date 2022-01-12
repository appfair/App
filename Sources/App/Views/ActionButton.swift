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
import SwiftUI

/// A capsule-shaped button for an action that dislays progress in the background of the button.
struct ActionButtonStyle: ButtonStyle {
    @Binding var progress: Double
    var primary: Bool = true
    var highlighted: Bool = false

    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        ActionButton(configuration: configuration, progress: progress, primary: primary, highlighted: highlighted)
    }

    private struct ActionButton: View {
        @Environment(\.isEnabled) var isEnabled
        @State var hovering = false

        var defaultColor: Color = Color.white
        var highlightColor: Color = Color.accentColor
        var disabledColor: Color = Color.secondary

        var configuration: ButtonStyle.Configuration
        var progress: Double
        var primary: Bool
        var highlighted: Bool

        var body: some View {
            configuration.label
                .font(Font.caption.weight(.bold))
                .foregroundColor(isEnabled ? internalColor : internalColor.opacity(0.7))
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .frame(minWidth: 65)
                .background(background(isPressed: configuration.isPressed))
                .onHover(perform: { self.hovering = $0 })
                .padding(1)
        }

        var internalColor: Color {
            isEnabled
                ? (primary ? (highlighted ? highlightColor : defaultColor) : highlightColor)
                : (primary ? (highlighted ? disabledColor : defaultColor)  : (highlighted ? defaultColor : disabledColor))
        }

        @ViewBuilder func background(isPressed: Bool) -> some View {
            Group {
                if isEnabled || (progress < 1.0) {
                    ProgressView(value: progress, total: 1.0, label: {
                        // the button itself handles the label
                        EmptyView()
                    }, currentValueLabel: {
                        EmptyView()
                    })
                    .progressViewStyle(CapsuleProgressViewStyle())
                } else {
                    Capsule().fill(highlighted ? defaultColor : disabledColor)
                }
            }
            .brightness(isPressed ? -0.25 : hovering && isEnabled ? -0.10 : 0.0)
        }
    }
}

struct ActionButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView(value: Double.random(in: 0.0...10.0), total: 10.0, label: {
            Text("Install")
        }, currentValueLabel: {
            //Text("ZZZ")
        })


        ProgressView(value: Double.random(in: 0.0...10.0), total: 10.0, label: {
            Text("Install")
        }, currentValueLabel: {
            //Text("ZZZ")
        })
            .progressViewStyle(CapsuleProgressViewStyle())
            .accentColor(Color.red)
            .frame(width: 80, height: 25)
            .padding()


        Button("LAUNCH", action: {})
            .buttonStyle(ActionButtonStyle(progress: .constant(Double.random(in: 0.0...1.0))))
            .padding()

        previewsActionButtons
    }

    static var previewsActionButtons: some View {
        Group {
            ForEach([ColorScheme.light, .dark], id: \.self) { colorScheme in
                Group {
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(progress: .constant(0.4)))
                        .padding()
                        //.background(Color(UXColor.textBackgroundColor))
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(progress: .constant(1.0)))
                        .padding()
                        //.background(Color(.controlAccentColor))
                    Button("LAUNCH", action: {})
                        .buttonStyle(ActionButtonStyle(progress: .constant(0.8)))
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
