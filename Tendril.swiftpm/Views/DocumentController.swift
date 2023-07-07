import SwiftUI
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

extension DocumentView {
    class DocumentController: ObservableObject {
        @Published var isWriting = false
        @Published var wordCount: Int?
        
        var textView: UITextView?
        private var chatGPT: ChatGPT = ChatGPT(key: "")
        
        func gptIfy() {
            guard !self.isWriting, let textView else { return }
            guard let text = textView.precedingText() else { return } // get text before selection
            guard let neededWords = self.omitNeedlessWords(text) else { return } // remove commented out text
            guard let messages = self.massage(text: text) else { return } // convert text into messages
            
            let settings = Settings()
            self.chatGPT.key = settings.apiKey
            self.chatGPT.model = settings.model
            self.chatGPT.temperature = Float(settings.temperature)
            self.chatGPT.systemMessage = settings.systemMessage
            
            DispatchQueue.main.async {
                self.isWriting = true
                textView.isUserInteractionEnabled = false
//                textView.isEditable = false

                defer {
                    self.isWriting = false
                    textView.isUserInteractionEnabled = true
//                    textView.isEditable = true
                }
                Task {
                    let m = [(role: "system", content: self.chatGPT.systemMessage)] + messages
                    switch await self.chatGPT.streamChatText(queries: messages) {
                    case .failure(let error):
                        self.textView?.insertText("\nCommunication Error:\n\(error.description)")
                        return
                    case .success(let results):
                        var selectionPoint = textView.selectedTextRange
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
        
        func omitNeedlessWords(_ words: String) -> String? {
            return words.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        }
        
        func massage(text: String) -> [(role: String, content: String)]? {
            return [(role: "user", content: text)]
        }
        
        func updateWordCount() {
            DispatchQueue.main.async {
                if let text = self.textView?.precedingText() {
                    let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                    let words = uneaten.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                    self.wordCount = words.count
                }
            }
        }
        
        func parse(_ input: String) -> [String] {
            enum QueryType {
                case Direction
                case Summary
                case Response
                case System
            }
            var queryType = QueryType.Response
            var accumulation: String = ""
            var newLine = false
            var output = [String]()
            for line in input.components(separatedBy: "\n") {
                if line.hasPrefix("System: ") {
                    output.append(accumulation)
                    accumulation = String(line.trimmingPrefix("System: "))
                    newLine = false
                    
                    queryType = .System
                } else if line.hasPrefix("Direction: ") {
                    output.append(accumulation)
                    accumulation = String(line.trimmingPrefix("Direction: "))
                    newLine = false
                    
                    queryType = .Direction
                } else if line.hasPrefix("Summary: ") {
                    output.append(accumulation)
                    accumulation = line
                    newLine = false
                    
                    queryType = .Summary
                } else if line.hasPrefix("-") {
                    output.append(accumulation)
                    accumulation = ""
                    newLine = false
                    
                    queryType = .Response
                } else if line == "" {
                    if queryType == .Direction {
                        output.append(accumulation)
                        accumulation = ""
                        
                    } else if queryType == .Summary {
                        output.append(accumulation)
                        accumulation = ""
                        
                    } else if queryType == .System {
                        output.append(accumulation)
                        accumulation = ""
                        
                    } else if accumulation != "" {
                        newLine = true
                    }
                    queryType = .Response
                } else {
                    if newLine {
                        accumulation += "\n"
                        newLine = false
                    }
                    if accumulation != "" {
                        accumulation += "\n"
                    }
                    accumulation += line
                }
            }
            output.append(accumulation)
            return output.filter{ $0 != "" }
        }
    }
    
}
