import SwiftUI

struct Settings {
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("systemMessage") var systemMessage: String = "You are a helpful assistant"
    @AppStorage("temperature") var temperature: Double = 0.7
    @AppStorage("isGPT4") var isGPT4: Bool = false
}

struct SettingsView: View {
    @Binding var settings: Settings
    
    var body: some View {
        TextField("API Key", text: settings.$apiKey)
        TextEditor(text: settings.$systemMessage)
            .border(Color.secondary, width: 1)
        Slider(value: settings.$temperature)//, in: 0...1.6, step: 0.1)
        Toggle("GPT4", isOn: settings.$isGPT4)
    }
}
