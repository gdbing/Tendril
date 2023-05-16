import SwiftUI
import HighlightedTextEditor

let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^", options: [])

struct ContentView: View {
    @State private var text: String = ""    
    
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
                let uneaten = text.removeMatches(to: betweenVs)
                text.append(uneaten)
            })
        }
    }
}
