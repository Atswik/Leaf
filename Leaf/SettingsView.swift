
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("quitWithoutNotify") private var quitWithoutNotify: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            
            Spacer()
            
            HStack {
                Text("Leaf")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.green.gradient)
                
                Image(systemName: "leaf.fill")
                    .imageScale(.large)
                    .foregroundStyle(Color.green.gradient)
            }
            .padding(1)
            
            Group {
                Toggle(isOn: $launchAtLogin) {
                    Text("Launch at login")
                        .padding(3)
                }
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) {
                    addLoginItem(launchAtLogin: launchAtLogin)
                }
                
                Toggle(isOn: $quitWithoutNotify) {
                    Text("Quit without notifying")
                        .padding(3)
                }
                .toggleStyle(.switch)
            }
            .fontDesign(.monospaced)
            .tint(Color.green)
            
            StepperView()
            
            Spacer()
            
            VStack {
                Divider().frame(width: 270).padding(.bottom, 8)
                HStack(alignment: .center, spacing: 5) {
                    
                    Text("Developed by")
                        .font(.system(size: 12))
                    Link("Satwik", destination: URL(string: "https://github.com/Atswik")!)
                        .padding(1)
                        .font(.system(size: 12))
                    Text("👀")
                }
                .fontDesign(.monospaced)
            }
        }
        .padding()
        .frame(width: 450, height: 350)
    }
    
    private func addLoginItem(launchAtLogin: Bool) {
        do {
            if launchAtLogin == true {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Error occurred: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}

struct StepperView: View {
    
    @AppStorage("closingTime") private var closingTime: Int = 10

    let options: [Int: String] = [
        5 : "5 mins",
        10 : "10 mins",
        15 : "15 mins",
        30 : "30 mins",
        60 : "1 hour",
        120 : "2 hours",
        240 : "4 hours"
    ]

    func incrementStep() {
        if closingTime < 15 {
            closingTime += 5
        } else {
            closingTime *= 2
        }
        if closingTime > 240 { closingTime = 5 }
    }

    func decrementStep() {
        if closingTime <= 15 {
            closingTime -= 5
        } else {
            closingTime /= 2
        }
        if closingTime < 5 { closingTime = 240 }
    }

    var body: some View {
        HStack {
            Stepper {
                HStack {
                    Text("Notify After")
                    Text("\(options[closingTime] ?? "Unknown")")
                        .frame(width: 64, height: 25)
                        .italic()
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4).stroke(Color.gray, lineWidth: 1.1)
                        )
                }
                
            } onIncrement: {
                incrementStep()
            } onDecrement: {
                decrementStep()
            }
            
            Text("Of Idle Time")
        }
        .fontDesign(.monospaced)
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

