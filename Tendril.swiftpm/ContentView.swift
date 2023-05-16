import SwiftUI
import SwiftChatGPT
import HighlightedTextEditor

let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^", options: [])

struct ContentView: View {
    private let chatGPT = ChatGPT(key: "")
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("systemMessage") private var systemMessage: String = "You are a helpful assistant"
    @AppStorage("temperature") private var temperature: Double = 1.2
    @AppStorage("isGPT4") private var isGPT4: Bool = false

    @State private var text: String = ""
    @ScaledMetric(relativeTo: .body) var maxWidth = 720    

    private let rules: [HighlightRule] = [
        HighlightRule(pattern: betweenVs, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
        HighlightRule(pattern: aboveCarats, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
    ]
    
    var body: some View {
        VStack {
            HighlightedTextEditor(text: $text, highlightRules: rules + .markdown)
                .padding()
                .frame(maxWidth: maxWidth, alignment: .center)
                .font(.body)
            // optional modifiers
//                .onCommit { print("commited") }
//                .onEditingChanged { print("editing changed") }
//                .onTextChange { print("latest text value", $0) }
//                .onSelectionChange { (range: NSRange) in
//                    print(range)
//                }
//                .introspect { editor in
//                    // access underlying UITextView or NSTextView
//                    editor.textView.backgroundColor = .systemBackground
//                }
            Button("append uneaten", action: {
                let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                text.append(uneaten)
            })
        }
        .onAppear {
            self.chatGPT.key = apiKey
            self.chatGPT.model = isGPT4 ? "gpt-4" : "gpt-3.5-turbo"
            self.chatGPT.temperature = Float(temperature)
            self.chatGPT.systemMessage = systemMessage
        }
        .onChange(of: apiKey, perform: { newValue in
            self.chatGPT.key = newValue
        })
        .onChange(of: isGPT4, perform: { newValue in
            self.chatGPT.model = newValue ? "gpt-4" : "gpt-3.5-turbo"
        })
        .onChange(of: temperature, perform: { newValue in
            self.chatGPT.temperature = Float(temperature)
        })
        .onChange(of: systemMessage, perform: { newValue in
            self.chatGPT.systemMessage = systemMessage
        })
    }
}
