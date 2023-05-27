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
    

    init() {
        if let data = UserDefaults.standard.data(forKey: "personae"), 
            let decodedItems = try? JSONDecoder().decode([Persona].self, from: data) {
                self.personae = decodedItems
        } else {
            self.personae = [Persona.defaultPersona]
        }        
    }
}
