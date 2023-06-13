import SwiftUI
import SwiftChatGPT

@main
struct Tendril: App {
    var gptifier = GPTifier()
    var settings = Settings()
    
    @AppStorage("projectBookmark")
    var projectBookmark: Data?
    // TODO just fetch this at init time
    // refresh stale url, if it can't be refreshed, reset it
    
    @State var projectURL: URL? 
        
    var body: some Scene {
        WindowGroup {
            ContentView(project: $projectURL, gpt: gptifier)
                .environmentObject(settings)
                .onChange(of: self.projectURL) { [oldURL = projectURL] newURL in
                    print("stopAccessingSecurityScopedResource \(oldURL)")
                    oldURL?.stopAccessingSecurityScopedResource()
                    if let newURL, 
                        newURL.startAccessingSecurityScopedResource() {
                        print("startAccessingSecurityScopedResource \(newURL)")
                        if let bookmark = try? newURL.bookmarkData(options: [], includingResourceValuesForKeys: [], relativeTo: nil) {
                            self.projectBookmark = bookmark
                        } else {
                            print("ERROR: failed to produce bookmark for \(newURL)")
                        }
                    }
                }
        }
    }
}
