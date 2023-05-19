import SwiftUI

struct Settings {
    @AppStorage("apiKey") var apiKey: String = ""
    @AppStorage("systemMessage") var systemMessage: String = "You are a helpful assistant"
    @AppStorage("temperature") var temperature: Double = 0.7
    @AppStorage("isGPT4") var isGPT4: Bool = false

}
