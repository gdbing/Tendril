import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    
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
                Section(header: Text("Model")) {
                    Toggle("GPT4", isOn: $settings.isGPT4)
                }
                NavigationLink("Persona: \(settings.selectedPersona.name)", destination: PersonaeView(personae: $settings.personae, selectedPersona: $settings.selectedPersona))
            }
        }
    }
    
    private struct PersonaeView: View {
        @Binding var personae: [Persona]
        @Binding var selectedPersona: Persona
        var body: some View {
            List {
                ForEach($personae, id: \.self) { $persona in
                    NavigationLink(destination: PersonaView(persona: $persona, selectedPersona: $selectedPersona), label: {
                        HStack {
                            if persona == selectedPersona {
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
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive, action: {
                            // TODO
                            // if starred item, top item is starred now
                            // if last item, create default item
                            print("nom nom")
                        }) {
                            Text("Delete")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(action: {
                            // TODO
                            print("⭐️")
                        }) {
                            Text("Star")
                        }
                    }
                    .contextMenu {
                        Button {
                            // TODO
                        } label: {
                            Label("do thing", systemImage: "star")
                        }
                        .disabled(persona == selectedPersona)
                        Button {
                            // TODO
                        } label: {
                            Label("another thing", systemImage: "house")
                        }
                        Button(role: .destructive) {
                            print("nom nom")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Persona", action: {
                        
                    })
                }
            }
        }
    }
    private struct PersonaView: View {
        @Binding var persona: Persona
        @Binding var selectedPersona: Persona
        @State var otherText: String = ""
        
        var body: some View {
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $persona.name)
                }
                Section(header: Text("System Message")) {
                    TextField("system message", text: $persona.message)
                    TextEditor(text: $otherText)
                        .frame(minHeight: 150)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction, content: {
                    Button {
                        if persona != selectedPersona {
                            selectedPersona = persona
                        }
                    } label: {
                        if persona == selectedPersona {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "star")
                        }
                    }
                })
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

