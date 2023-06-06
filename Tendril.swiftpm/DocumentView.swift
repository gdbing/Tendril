import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

struct DocumentView: UIViewRepresentable {
    @State private var textView = UITextView()
    @Binding var text: String
    @Binding var isGPTWriting: Bool
    
    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
    
    func makeUIView(context: Context) -> UITextView {
        let parentWidth = textView.superview?.frame.size.width ?? 0
        let insetSize = parentWidth > maxWidth ? (parentWidth - maxWidth) / 2 : 0.0
        updateInsets(insetSize)
        
        textView.text = self.text
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.systemBackground
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // This is not needed if `textView` is the primary source of truth, and, in fact, was the source of a ton of annoying glitches and issues when there are >500 words in the view
        
        // uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func setTextColor(_ color: UIColor) {
        var attributes = textView.typingAttributes
        attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
        textView.typingAttributes = attributes
    }
    
    class Coordinator: NSObject, UITextViewDelegate {        
        var parent: DocumentView
        
        init(_ parent: DocumentView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            self.parent.setTextColor(.label)
        }
    }
}

extension DocumentView {
    func updateInsets(_ width: CGFloat) {
        let insetSize = width > maxWidth ? ((width - maxWidth) / 2) : 0.0 
        textView.textContainerInset = UIEdgeInsets(top: 0.0,
                                                   left: insetSize, 
                                                   bottom: 0.0,
                                                   right: insetSize)
    }
    
    func GPTify(chatGPT: ChatGPT) {
        guard !self.isGPTWriting else {
            return
        }
        self.isGPTWriting = true
        let uneaten = self.text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        DispatchQueue.main.async {
            Task {
                var selectionPoint = textView.selectedTextRange
                switch await chatGPT.streamChatText(query: uneaten) {
                case .failure(let error):
                    self.textView.insertText("\nCommunication Error:\n\(error.description)")
                    self.isGPTWriting = false
                    return
                case .success(let results):
                    for try await result in results {
                        if let result {
                            DispatchQueue.main.async {
                                textView.selectedTextRange = selectionPoint
                                self.setTextColor(.secondaryLabel)
                                
                                self.textView.insertText(result)
                                
                                selectionPoint = textView.selectedTextRange
                                self.setTextColor(.label)
                            }
                        }
                    }
                    self.isGPTWriting = false
                }
            }
        }
    }
}
