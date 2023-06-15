import SwiftUI
import SwiftChatGPT

@main
struct Tendril: App {
    var gptifier = GPTifier()
    var settings = Settings()
        
    @State var projectURL: URL?
    
    var body: some Scene {
        WindowGroup {
            ContentView(project: $projectURL, gpt: gptifier)
                .environmentObject(settings)
                .onChange(of: self.projectURL) { [oldURL = projectURL] newURL in
                    oldURL?.stopAccessingSecurityScopedResource()
                    let _ = newURL?.startAccessingSecurityScopedResource()
                    settings.projectURL = newURL
                }
        }
    }
}
