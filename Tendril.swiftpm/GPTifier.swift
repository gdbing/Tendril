import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

class GPTifier: ObservableObject {
    var chatGPT: ChatGPT = ChatGPT(key: "")
    var textView: UITextView?
    private var settings: Settings = Settings()

    @Published var isWriting = false
    
    var wordCount: Int? {
        get {
            guard let textView else { return nil } 
            let words = textView.text.components(separatedBy: .whitespacesAndNewlines)
            let filteredWords = words.filter { !$0.isEmpty }
            return filteredWords.count
        }
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
        guard !self.isWriting, let textView = self.textView else {
            return
        }
        
        self.chatGPT.key = settings.apiKey
        self.chatGPT.model = settings.model
        self.chatGPT.temperature = Float(settings.temperature)
        self.chatGPT.systemMessage = settings.systemMessage

        let text = self.eat(textView: textView)
        let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        
        DispatchQueue.main.async {            
            self.isWriting = true
            var selectionPoint = textView.selectedTextRange
            textView.setTextColor(.secondaryLabel)
            
            defer { 
                self.isWriting = false 
                textView.setTextColor(.label)
            }

            let words = uneaten.components(separatedBy: .whitespacesAndNewlines)
            let filteredWords = words.filter { !$0.isEmpty }
            let wordCount = filteredWords.count
            print("gptify \(self.chatGPT.model) | \(String(format: "%.1f°", self.chatGPT.temperature)) | \(wordCount) \(wordCount == 1 ? "word " : "words")")

            Task {
                switch await self.chatGPT.streamChatText(query: uneaten) {
                case .failure(let error):
                    textView.insertText("\nCommunication Error:\n\(error.description)")
                    return
                case .success(let results):
                    for try await result in results {
                        if let result {
                            DispatchQueue.main.async {
                                textView.selectedTextRange = selectionPoint
                                textView.insertText(result)
                                selectionPoint = textView.selectedTextRange
                            }
                        }
                    }
                }
            }
        }
    }
}
