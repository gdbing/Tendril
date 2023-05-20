import SwiftUI

class Settings: ObservableObject {
    @AppStorage("apiKey") 
    var apiKey: String = "" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @AppStorage("systemMessage") 
    var systemMessage: String = "You are a helpful assistant" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    @AppStorage("temperature") 
    var temperature: Double = 0.7 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    @AppStorage("isGPT4") 
    var isGPT4: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Text("API Key:")
                    SecureField("API Key", text: $settings.apiKey)  
                } 
                HStack {
                    Text(String(format: "Temperature %.1f°", settings.temperature))
                        .monospacedDigit()
                    Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                }
                Toggle("GPT4", isOn: $settings.isGPT4)
                //            }
                VStack(alignment:.leading) {
                    ZStack(alignment: .topLeading) {
                        Text("System Message:")
                            .font(.caption)
                        Text(settings.systemMessage)
                            .padding(.top, 18.5)
                            .padding(.horizontal, 5)
//                            .hidden()
                        TextEditor(text: $settings.systemMessage)
                            .padding(.top, 10)
                    }
                }
            }
        }
    }
}

extension Settings {
    static let preview = Settings()
}
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Settings.preview)
    }
}
