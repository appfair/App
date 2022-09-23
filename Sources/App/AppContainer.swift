import FairApp

struct ClockView: View {
    @State var currentTime: (hour: String, minute: String) = ("", "")
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let backgroundColor = Color.accentColor
    let clockColor = Color.red

    var body: some View {
        GeometryReader { parent in
            let fontSize = parent.size.height * 0.4
            let clockFont = Font.system(size: fontSize)
            let hSpacing = fontSize * 0.25

            VStack {
                Text(currentTime.hour)
                    .padding(.bottom, -hSpacing)
                Text(currentTime.minute)
                    .padding(.top, -hSpacing)
            }
            .font(clockFont)
            .frame(width: parent.size.width, height: parent.size.height)
            .foregroundColor(clockColor)
            .background(backgroundColor)
            .cornerRadius(parent.size.height * 0.2)
            .shadow(radius: 3)
        }
        .onReceive(timer) { currentDate in
            let components = Calendar.current.dateComponents([.hour, .minute], from: currentDate)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0

            currentTime = (String(format: "%02d", hour), String(format: "%02d", minute))
            dbg(currentTime)

        }
//        .padding(10)
    }
}
