import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

class GPTifier: ObservableObject {
    var chatGPT: ChatGPT = ChatGPT(key: "")
    var textView: UITextView?

    @Published var isWriting = false
    
    func updateWordCount() -> Int? {
//        return nil
        guard let textView else {
            return nil
        }
        let text = self.eat(textView: textView)
        let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        let words = uneaten.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    struct Message: Codable {
        public let role: String?
        public let content: String
    }

    // TODO: Director mode
    //       Parse "Summary: blah blah blah" as user message
    //       Parse "Direction: blah blah blah" as system message
    //       Ideally, do syntax highlighting of them
    func messagify(text: String) -> [Message] {
        var messages = [Message]()
        for line in text.components(separatedBy: .newlines) {
            if line.hasPrefix("System: ") {
                let systemMessage = Message(role: "system", content: "")
                messages.append(systemMessage)
            }
        }
        return messages
    }
    
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
        print("GPTify")
        
        guard !self.isWriting, let textView = self.textView else {
            return
        }
        let settings = Settings()
        self.chatGPT.key = settings.apiKey
        self.chatGPT.model = settings.model
        self.chatGPT.temperature = Float(settings.temperature)
        self.chatGPT.systemMessage = settings.systemMessage

        DispatchQueue.main.async {
            let text = self.eat(textView: textView)
            let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)

            self.isWriting = true
            var selectionPoint = textView.selectedTextRange
            textView.setTextColor(.secondaryLabel)
            
            defer { 
                self.isWriting = false 
                textView.setTextColor(.label)
            }

            Task {
                let messages = [(role: "system", content: self.chatGPT.systemMessage),
                                (role: "user", content: uneaten)]
                switch await self.chatGPT.streamChatText(queries: messages) {
                case .failure(let error):
                    textView.insertText("\nCommunication Error:\n\(error.description)")
                    return
                case .success(let results):
                    for try await result in results {
                        if let result {
                            DispatchQueue.main.async {
                                textView.selectedTextRange = selectionPoint
                                textView.setTextColor(UIColor.secondaryLabel)
                                textView.insertText(result)
                                selectionPoint = textView.selectedTextRange
                                textView.setTextColor(UIColor.label)
                            }
                        }
                    }
                }
            }
        }
    }
}
