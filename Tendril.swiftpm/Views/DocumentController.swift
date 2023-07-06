import SwiftUI

extension DocumentView {
    class DocumentController: ObservableObject {
        @Published var isWriting = false
        @Published var wordCount: Int?
        
        var textView: UITextView?
        private var gpt: GPTifier = GPTifier()
        
        func gptIfy() {
            print("controller gpt \(String(describing: self.textView))")
            if let textView {
                self.gpt.textView = textView
                self.gpt.GPTify()
            }
        }
        
        func updateWordCount() {
            DispatchQueue.main.async {
                let count = self.gpt.updateWordCount()
                if let count {
                    self.wordCount = count
                }
            }
        }
    }
}
