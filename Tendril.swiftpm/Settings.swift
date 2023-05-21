import SwiftUI

typealias Persona = [String: String]
extension Persona {
    init(name: String, message: String, id: UUID = UUID()) {
        self.init()
        self["name"] = name
        self["message"] = message
        self["id"] = id.uuidString
    }
    
    var name: String {
        get { self["name"] ?? ""}
        set { self["name"] = newValue }
    }
    var message: String {
        get { self["message"] ?? "" }
        set { self["message"] = newValue }
    }
    var id: String {
        get { self["id"] ?? "" }
    }
}

extension Persona {
    static let defaultPersona = Persona(name: "Default", message: "You are a helpful assistant")
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
    
    @Published var selectedPersona: Persona {
        didSet {
            UserDefaults().setValue(selectedPersona, forKey: "selectedPersona")
        }
    }
    
    @Published var personae: [Persona] {
        didSet {
            UserDefaults().setValue(personae, forKey: "personae")
            print("didSet personae")
        }
    }
    
    init() {
        self.selectedPersona = UserDefaults().dictionary(forKey: "selectedPersona") as? Persona ?? Persona.defaultPersona
        self.personae = UserDefaults().array(forKey: "personae") as? [Persona] ?? [Persona.defaultPersona]
    }
}
