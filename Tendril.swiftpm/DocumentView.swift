import SwiftUI
import HighlightedTextEditor

let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

struct DocumentView: View {
    @Binding var text: String

    private let rules: [HighlightRule] = [
        HighlightRule(pattern: betweenVs, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
        HighlightRule(pattern: aboveCarats, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
    ]

    @ScaledMetric(relativeTo: .body) var maxWidth = 720    

    var body: some View {
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

    }
}
