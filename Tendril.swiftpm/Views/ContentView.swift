import SwiftUI
import SwiftChatGPT

struct ContentView: View {
    @Binding var document: TextDocument
    @ObservedObject var gptifier: GPTifier
        
    @EnvironmentObject private var settings: Settings
    @State private var showingSettings: Bool = false

    var body: some View {
        DocumentView(text: $document.text, gpt: gptifier)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.showingSettings = true
                    }, label: {
                        Image(systemName: "gear")
                    })
                    .keyboardShortcut(",", modifiers: [.command]) 
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.gptifier.GPTify()
                    }, label: {
                        Image(systemName: "bubble.left.fill")
                    })
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(self.gptifier.isWriting)
                }
                ToolbarItem(placement: .automatic) {
                    let words = document.text.components(separatedBy: .whitespacesAndNewlines)
                    let filteredWords = words.filter { !$0.isEmpty }
                    let wordCount = filteredWords.count
                    Text("\(self.settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo") | \(String(format: "%.1f°", self.settings.temperature)) | \(wordCount) \(wordCount == 1 ? "word " : "words")")
                        .monospacedDigit()
                }
            }
            .onAppear {
                self.gptifier.chatGPT.key = settings.apiKey
                self.gptifier.chatGPT.model = settings.isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
                self.gptifier.chatGPT.temperature = Float(settings.temperature)
                self.gptifier.chatGPT.systemMessage = settings.systemMessage
            }
            .onChange(of: settings.apiKey, perform: { newValue in
                self.gptifier.chatGPT.key = newValue
            })
            .onChange(of: settings.isGPT4, perform: { newValue in
                self.gptifier.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo"
            })
            .onChange(of: settings.temperature, perform: { newValue in
                self.gptifier.chatGPT.temperature = Float(newValue)
            })
            .onChange(of: settings.systemMessage, perform: { newValue in
                self.gptifier.chatGPT.systemMessage = newValue
            })

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mobyDickChapter9 = """
Father Mapple rose, and in a mild voice of unassuming authority ordered the scattered people to condense.  "Starboard gangway, there! side away to larboard--larboard gangway to starboard! Midships! midships!"
There was a low rumbling of heavy sea-boots among the benches, and a still slighter shuffling of women's shoes, and all was quiet again, and every eye on the preacher.
He paused a little; then kneeling in the pulpit's bows, folded his large brown hands across his chest, uplifted his closed eyes, and offered a prayer so deeply devout that he seemed kneeling and praying at the bottom of the sea.
This ended, in prolonged solemn tones, like the continual tolling of a bell in a ship that is foundering at sea in a fog--in such tones he commenced reading the following hymn; but changing his manner towards the concluding stanzas, burst forth with a pealing exultation and joy--
"The ribs and terrors in the whale, Arched over me a dismal gloom, While all God's sun-lit waves rolled by, And lift me deepening down to doom.
"I saw the opening maw of hell, With endless pains and sorrows there; Which none but they that feel can tell-- Oh, I was plunging to despair.
"In black distress, I called my God, When I could scarce believe him mine, He bowed his ear to my complaints-- No more the whale did me confine.
"With speed he flew to my relief, As on a radiant dolphin borne; Awful, yet bright, as lightning shone The face of my Deliverer God.
"My song for ever shall record That terrible, that joyful hour; I give the glory to my God, His all the mercy and the power.
Nearly all joined in singing this hymn, which swelled high above the howling of the storm.  A brief pause ensued; the preacher slowly turned over the leaves of the Bible, and at last, folding his hand down upon the proper page, said: "Beloved shipmates, clinch the last verse of the first CHAPTER of Jonah--'And God had prepared a great fish to swallow up Jonah.'"
"Shipmates, this book, containing only four chapters--four yarns--is one of the smallest strands in the mighty cable of the Scriptures. Yet what depths of the soul does Jonah's deep sealine sound! what a pregnant lesson to us is this prophet!  What a noble thing is that canticle in the fish's belly!  How billow-like and boisterously grand!  We feel the floods surging over us; we sound with him to the kelpy bottom of the waters; sea-weed and all the slime of the sea is about us!  But WHAT is this lesson that the book of Jonah teaches? Shipmates, it is a two-stranded lesson; a lesson to us all as sinful men, and a lesson to me as a pilot of the living God.  As sinful men, it is a lesson to us all, because it is a story of the sin, hard-heartedness, suddenly awakened fears, the swift punishment, repentance, prayers, and finally the deliverance and joy of Jonah. As with all sinners among men, the sin of this son of Amittai was in his wilful disobedience of the command of God--never mind now what that command was, or how conveyed--which he found a hard command. But all the things that God would have us do are hard for us to do--remember that--and hence, he oftener commands us than endeavors to persuade.  And if we obey God, we must disobey ourselves; and it is in this disobeying ourselves, wherein the hardness of obeying God consists.
"""
        let doc = TextDocument(text: mobyDickChapter9)
        NavigationStack {
            ContentView(document: .constant(doc), gptifier: GPTifier())
                .environmentObject(Settings())
        }
    }
}
