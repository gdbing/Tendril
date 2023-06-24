import SwiftUI

@main
struct Tendril: App {
    var settings = Settings()        
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
