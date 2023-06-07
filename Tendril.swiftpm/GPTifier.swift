import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

class GPTifier: ObservableObject {
    var chatGPT: ChatGPT = ChatGPT(key: "")
    var textView: UITextView?
    
    @Published var isWriting = false
    
    func eat(textView: UITextView) -> String {
        if let selection = textView.selectedTextRange {
            if let selectedText = textView.text(in: selection), 
                selectedText.count > 0 {
                return selectedText
            } else if let precedingRange = textView.textRange(from: textView.beginningOfDocument, to: selection.end),
                      let precedingText = textView.text(in: precedingRange),
                      precedingText.count > 0 {
                return precedingText
            } 
        }
        
        return textView.text
    }
    
    func GPTify() {
        guard !self.isWriting, let textView = self.textView else {
            return
        }
        
        let text = self.eat(textView: textView)
        let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        
        self.isWriting = true
        DispatchQueue.main.async {
            var selectionPoint = textView.selectedTextRange
            Task {
                defer { self.isWriting = false }
                switch await self.chatGPT.streamChatText(query: uneaten) {
                case .failure(let error):
                    textView.insertText("\nCommunication Error:\n\(error.description)")
                    return
                case .success(let results):
                    for try await result in results {
                        if let result {
                            DispatchQueue.main.async {
                                textView.selectedTextRange = selectionPoint
                                self.setTextColor(.secondaryLabel)
                                
                                textView.insertText(result)
                                
                                selectionPoint = textView.selectedTextRange
                                self.setTextColor(.label)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setTextColor(_ color: UIColor) {
        if let textView {
            var attributes = textView.typingAttributes
            attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
            textView.typingAttributes = attributes
        }
    }
}
