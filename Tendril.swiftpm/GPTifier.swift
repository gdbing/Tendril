import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

class GPTifier: ObservableObject {
    @Published var isWriting = false
    private var textView: UITextView
    
    init(_ textView: UITextView) {
        self.textView = textView
    }
    
    func GPTify(chatGPT: ChatGPT) {
        guard !self.isWriting else {
            return
        }
        self.isWriting = true
        let uneaten = self.textView.text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        DispatchQueue.main.async {
            Task {
                var selectionPoint = self.textView.selectedTextRange
                switch await chatGPT.streamChatText(query: uneaten) {
                case .failure(let error):
                    self.textView.insertText("\nCommunication Error:\n\(error.description)")
                    self.isWriting = false
                    return
                case .success(let results):
                    for try await result in results {
                        if let result {
                            DispatchQueue.main.async {
                                self.textView.selectedTextRange = selectionPoint
                                self.setTextColor(.secondaryLabel)
                                
                                self.textView.insertText(result)
                                
                                selectionPoint = self.textView.selectedTextRange
                                self.setTextColor(.label)
                            }
                        }
                    }
                    self.isWriting = false
                }
            }
        }
    }
    
    func setTextColor(_ color: UIColor) {
        var attributes = self.textView.typingAttributes
        attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
        self.textView.typingAttributes = attributes
    }
}
