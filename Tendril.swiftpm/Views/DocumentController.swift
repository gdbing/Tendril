import SwiftUI
import SwiftAnthropic
import SwiftChatGPT

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

extension DocumentView {
    class DocumentController: ObservableObject {
        @Published var isWriting = false
        @Published var wordCount: Int?
        
        var textView: UITextView?
        private var chatGPT: ChatGPT = ChatGPT(key: "")
        
        func streamAnthropic() {
            guard !self.isWriting, let textView else { return }
            guard let text = textView.precedingText() else { return } // get text before selection
            guard let neededWords = self.omitNeedlessWords(text) else { return } // remove commented out text
            guard let queries = self.massage(text: neededWords) else { return } // convert text into messages

            let settings = Settings()

            let anthropicMessages = queries.map {
                let role: MessageParameter.Message.Role = $0.role == "user" ? .user : .assistant
                let content: MessageParameter.Message.Content = .text($0.content)
                return MessageParameter.Message(role: role, content: content)
            }
            let parameters = MessageParameter(
                model: .claude3Haiku,
                messages: anthropicMessages,
                maxTokens: 2048,
                system: settings.systemMessage,
                stream: true,
                temperature: settings.temperature
            )
            let anthropicApiKey = ""
            let service = AnthropicServiceFactory.service(apiKey: anthropicApiKey)
            DispatchQueue.main.async {
                Task {
                    self.isWriting = true
                    textView.isEditable = false
                    textView.isSelectable = false
                    textView.setTextColor(UIColor.secondaryLabel)

                    defer {
                        self.isWriting = false
                        textView.isEditable = true
                        textView.isSelectable = true
                        textView.setTextColor(UIColor.label)
                    }
                    let stream = try await service.streamMessage(parameters)
                    //                     isLoading = false
                    for try await result in stream {
                        let content = result.delta?.text ?? ""
                        DispatchQueue.main.async {
                            textView.insertText(content)
                        }
                    }

                }
            }
        }

        func gptIfy() {
            guard !self.isWriting, let textView else { return }
            guard let text = textView.precedingText() else { return } // get text before selection
            guard let neededWords = self.omitNeedlessWords(text) else { return } // remove commented out text
            guard let queries = self.massage(text: neededWords) else { return } // convert text into messages
            let messages = [(role: "system", content: self.chatGPT.systemMessage)] + queries
            
            for message in messages {
                print("""
                         role: \(message.role)
                      content: \(message.content)

                      """)
            }
            
            let settings = Settings()
            self.chatGPT.key = settings.apiKey
            self.chatGPT.model = settings.model
            self.chatGPT.temperature = Float(settings.temperature)
            self.chatGPT.systemMessage = settings.systemMessage
            
            DispatchQueue.main.async {
                Task {
                    self.isWriting = true
                    textView.isEditable = false
                    textView.isSelectable = false
                    textView.setTextColor(UIColor.secondaryLabel)
                    
                    defer {
                        self.isWriting = false
                        textView.isEditable = true
                        textView.isSelectable = true
                        textView.setTextColor(UIColor.label)
                    }
                    
                    switch await self.chatGPT.streamChatText(queries: messages) {
                    case .failure(let error):
                        self.textView?.insertText("\nCommunication Error:\n\(error.description)")
                        return
                    case .success(let results):
                        for try await result in results {
                            if let result {
                                DispatchQueue.main.async {
                                    textView.insertText(result)
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
            enum QueryType {
                case System
                case Direction
                case User
                case Response
            }
            
            var queryType = QueryType.Response
            var messages = [(role: String, content: String)]()
            let append = { (content: String) in
                switch queryType {
                case .System:
                    messages.append((role: "system", content: content))
                case .Direction:
                    messages.append((role: "user", content: content))
                case .User:
                    messages.append((role: "user", content: content))
                default:
                    messages.append((role: "assistant", content: content))
                }
            }
            
            var accumulation: String = ""
            var newLine = false
            for line in text.components(separatedBy: "\n") {
                if line.hasPrefix("System: ") {
                    append(accumulation)
                    accumulation = String(line.trimmingPrefix("System: "))
                    newLine = false
                    
                    queryType = .System
                } else if line.hasPrefix("Direction: ") {
                    append(accumulation)
//                    accumulation = String(line.trimmingPrefix("Direction: "))
                    accumulation = line
                    newLine = false
                    
                    queryType = .Direction
                } else if line.hasPrefix("user: ") {
                    append(accumulation)
                    accumulation = String(line.trimmingPrefix("user: "))
                    newLine = false
                    
                    queryType = .User
                } else if line.hasPrefix("Summary: ") {
                    append(accumulation)
                    accumulation = line
                    newLine = false
                    
                    queryType = .User
                } else if line == "-" {
                    append(accumulation)
                    accumulation = ""
                    newLine = false
                    
                    queryType = .Response
                } else if line == "" {
                    if queryType == .Response {
                        if accumulation != "" {
                            newLine = true
                        } 
                    } else {
                        append(accumulation)
                        accumulation = ""
                        queryType = .Response
                    }
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
            append(accumulation)
            return messages.filter { $0.content != "" }
        }
        
        func updateWordCount() {
            DispatchQueue.main.async {
                if let text = self.textView?.precedingText() {
//                    let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                    let words = text.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                    self.wordCount = words.count
                }
            }
        }
    }
}
