import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @State var newPersona: Persona = Persona()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("API Key:")) {
                    SecureField("", text: $settings.apiKey)  
                } 
                Section(header: Text("Temperature")) {
                    HStack {
                        Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                        Text(String(format: "%.1f°", settings.temperature))
                            .monospacedDigit()
                    }
                }
                Picker(selection: $settings.model, label: Text("Model")) {
                    // gpt-3.5-turbo-0301 and gpt-4-0314 will be deprecated and discontinued on Sept13,2023 
                    Text("gpt-3.5-turbo").tag("gpt-3.5-turbo")
                    Text("gpt-3.5-turbo-16k").tag("gpt-3.5-turbo-16k")
                    Text("gpt-3.5-turbo-0301").tag("gpt-3.5-turbo-0301")
                    Text("gpt-3.5-turbo-0613").tag("gpt-3.5-turbo-0613")
                    Text("gpt-4").tag("gpt-4")
                    Text("gpt-4-32k").tag("gpt-4-32k")
                    Text("gpt-4-0314").tag("gpt-4-0314")
                    Text("gpt-4-0613").tag("gpt-4-0613")
                    Text("gpt-4-1106-preview").tag("gpt-4-1106-preview")
                }
                Section(header: Text("Persona")) {
                    ForEach($settings.personae) { $persona in
                        PersonaNavLink(persona: $persona)
                    }
                    let newView = PersonaView(name: $newPersona.name,
                                              message: $newPersona.message,
                                              isStarred: $newPersona.isSelected)
                        .onDisappear(perform: {
                            if newPersona.name.count > 0, newPersona.message.count > 0 {
                                settings.personae.append(newPersona)
                            }
                            newPersona = Persona()
                        })
                    NavigationLink(destination: newView) {
                        Text("New Persona")
                    }
                }
            }
        }
    }
    
    private struct PersonaNavLink: View {
        @Binding var persona: Persona
        @EnvironmentObject var settings: Settings

        func toggleStar() {
            for index in settings.personae.indices {
                settings.personae[index].isSelected = false
            }
            persona.isSelected = true
        }
        func delete() {
            let isSelected = persona.isSelected
            
            settings.personae.removeAll(where: { $0.id == persona.id })
            
            if settings.personae.count == 0 {
                var defaultPersona = Persona.defaultPersona
                defaultPersona.isSelected = true
                settings.personae = [defaultPersona]
            } else if isSelected {
                let index = settings.personae.startIndex
                settings.personae[index].isSelected = true
            }
        }
        
        var body: some View {
            let dest = PersonaView(name: $persona.name, 
                                   message: $persona.message,
                                   isStarred: $persona.isSelected)
            NavigationLink(destination: dest) {
                HStack {
                    if persona.isSelected {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    } else {
                        Image(systemName: "star.fill")
                            .hidden()
                    }
                    VStack(alignment: .leading) {
                        Text(persona.name)
                        Text(persona.message)
                            .lineLimit(1)
                            .font(.caption)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive, action: {
                        self.delete()
                    }) {
                        Text("Delete")
                    }
                }
                .tint(.red)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button(action: {
                        toggleStar()
                    }) {
                        Image(systemName: "star")
                    }
                    .disabled(persona.isSelected)
                }
                .tint(.yellow)
                .contextMenu {
                    Button {
                        toggleStar()
                    } label: {
                        Label("", systemImage: "star")
                    }
                    .disabled(persona.isSelected)
                    Button {
                        var dup = persona
                        dup.id = UUID()
                        if let index = settings.personae.firstIndex(of: persona) {
                            dup.isSelected = false
                            settings.personae.insert(dup, at: index.advanced(by: 1))
                        }
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button(role: .destructive) {
                        self.delete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                }
            }
        }
    }
    
    private struct NewPersonaNavLink: View {
        @State var persona: Persona = Persona()
        @EnvironmentObject var settings: Settings

        var body: some View {
            let dest = PersonaView(name: $persona.name, 
                                   message: $persona.message, 
                                   isStarred: $persona.isSelected)
                .onDisappear(perform: {
                    if persona.message.count > 0 {
                        settings.personae.append(persona)
                    }
                })
            NavigationLink(destination: dest) {
                Text("New Persona")
            }
        }
    }

    private struct PersonaView: View {
        @Binding var name: String
        @Binding var message: String
        @Binding var isStarred: Bool
        
        var body: some View {
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("System Message")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 150, maxHeight: 600)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction, content: {
//                    Button {
//                        
//                    } label: {
//                        if isStarred {
//                            Image(systemName: "star.fill")
//                                .foregroundColor(.yellow)
//                        } else {
//                            Image(systemName: "star")
//                        }
//                    }
                    Toggle("", isOn: $isStarred)
                        .toggleStyle(StarToggleStyle())
                })
            }
        }
    }
    private struct StarToggleStyle: ToggleStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            if configuration.isOn {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        configuration.isOn.toggle()
                    }
            } else {
                Image(systemName: "star")
                    .onTapGesture {
                        configuration.isOn.toggle()
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

