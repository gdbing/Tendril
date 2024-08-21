import SwiftUI

struct Persona: Identifiable, Codable, Hashable {
    var name: String = ""
    var message: String = ""
    var id: UUID = UUID()
    var isSelected: Bool = false
}

extension Persona {
    static let defaultPersona = Persona(name: "Default", message: "You are a helpful assistant", isSelected: true)
}

class Settings: ObservableObject {
    @AppStorage("apiKey")
    var apiKey: String = "" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    @AppStorage("anthropicKey")
    var anthropicKey: String = "" {
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
    
    @AppStorage("model")
    var model: String = "gpt-4o" {
        willSet(newModel) {
            if model != newModel && prevModel != newModel {
                prevModel = model
            }
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    @AppStorage("prevModel")
    var prevModel: String = "gpt-4o" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
            
    @Published var personae: [Persona] {
        didSet {
            if let data = try? JSONEncoder().encode(personae) {
                UserDefaults().setValue(data, forKey: "personae")
            }
        }
    }
    
    var systemMessage: String {
        get {
            personae.first(where: { $0.isSelected })?.message ?? "You are a helpful assistant"
        }
    }
    
    private let urlKey = "projectBookmark"
    @Published var projectURL: URL? {
        didSet {
            if let bookmark = try? projectURL?.bookmarkData(options: [], includingResourceValuesForKeys: [], relativeTo: nil) {
                UserDefaults().set(bookmark, forKey: urlKey)
            } else {
                print("ERROR: failed to produce bookmark for \(String(describing: projectURL))")
            }
        }
    }

    init() {
        if let data = UserDefaults().data(forKey: "personae"), 
            let decodedItems = try? JSONDecoder().decode([Persona].self, from: data) {
                self.personae = decodedItems
        } else {
            self.personae = [Persona.defaultPersona]
        }

        var isStale = false
        if let data = UserDefaults().data(forKey: urlKey) {
            if let url = try? URL(resolvingBookmarkData: data, 
                                  options: [], 
                                  relativeTo: nil, 
                                  bookmarkDataIsStale: &isStale) {
                self.projectURL = url
                
                
                if isStale {
                    let newBookmark = try? url.bookmarkData(options: [], includingResourceValuesForKeys: [], relativeTo: nil)
                    UserDefaults().set(newBookmark, forKey: urlKey)
                }
            }
        }
    }
}
