import SwiftUI
import SwiftAnthropic

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

//extension DocumentView {
    class DocumentController: ObservableObject {
        @Published var isWriting = false
        @Published var wordCount: Int?
        
        var textView: UITextView?

        func gptIfy() {
            switch Settings().model {
            case "claude-3-opus-20240229", "claude-3-5-sonnet-20240620", "claude-3-haiku-20240307":
                streamAnthropic()
            case "gpt-3.5-turbo", "gpt-4o", "gpt-4o-mini", "gpt-4o-2024-08-06", "gpt-4o-2024-05-13":
                streamChatGPT()
            default:
                print("invalid model selected")
            }
        }

        func merge(messages: [(role: String, content: String)]) -> [(role: String, content: String)]? {
            var mergedMessages = [(role: String, content: String)]()
            guard let firstMessage = messages.first else { return nil }
            
            var currentRole = firstMessage.role
            var currentContent = firstMessage.content
            for message in messages.dropFirst() {
                if message.role == currentRole {
                    currentContent += "\n\n" + message.content
                } else {
                    mergedMessages.append((role: currentRole, content: currentContent))
                    currentRole = message.role
                    currentContent = message.content
                }
            }
            mergedMessages.append((role: currentRole, content: currentContent))
            
            return mergedMessages
        }

        func streamAnthropic() {
            guard !self.isWriting, let textView else { return }
            guard let text = textView.precedingText() else { return } // get text before selection
            guard let neededWords = self.omitNeedlessWords(text) else { return } // remove commented out text
            guard let queries = self.massage(text: neededWords) else { return } // convert text into messages
            guard let mergedQueries = self.merge(messages: queries) else { return }
            
            
            let settings = Settings()

            guard let model: SwiftAnthropic.Model = {
                switch settings.model {
                case "claude-3-opus-20240229": return .claude3Opus
                case "claude-3-5-sonnet-20240620": return .claude35Sonnet
                case "claude-3-haiku-20240307": return .claude3Haiku
                default: return nil
                }
            }() else { return }

            var anthropicMessages = mergedQueries.map {
                let role: MessageParameter.Message.Role = $0.role == "user" ? .user : .assistant

                if $0.content.hasSuffix("\n^CACHE") {
                    let content = String($0.content.dropLast("\n^CACHE".count))
                    print("cached ...\(content.suffix(40))")
                    let cache = MessageParameter.Message.Content.ContentObject.cache(.init(type: .text, text: content, cacheControl: .init(type: .ephemeral)))
                    return MessageParameter.Message(role: role, content: .list([cache]))
                }
                
                let content: MessageParameter.Message.Content = .text($0.content)
                return MessageParameter.Message(role: role, content: content)
            }
            if anthropicMessages.first?.role != "user" {
                let firstMessage = MessageParameter.Message(role: .user, content: .text(settings.systemMessage))
                anthropicMessages = [firstMessage] + anthropicMessages
            }
            
            let parameters = MessageParameter(
                model: model,
                messages: anthropicMessages,
                maxTokens: 2048,
                system: .text(settings.systemMessage),
                stream: true,
                temperature: max(settings.temperature, 1.0)
            )
            
            let anthropicApiKey = settings.anthropicKey
            let betaHeaders = ["prompt-caching-2024-07-31"]
            let service = AnthropicServiceFactory.service(apiKey: anthropicApiKey, betaHeaders: betaHeaders)
            

            Task { @MainActor in
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
                for try await result in stream {
                    if let content = result.delta?.text {
                        textView.insertText(content)
                    }
                    let t = result.type
                    
                    if let createdCacheTokens = result.message?.usage.cacheCreationInputTokens {
                        print("type: \(t) createdCacheTokens \(createdCacheTokens)")
                    }
                    if let readCacheTokens = result.message?.usage.cacheReadInputTokens {
                        print("type: \(t) readCacheTokens \(readCacheTokens)")
                    }
                    if let inputT = result.message?.usage.inputTokens {
                        print("type: \(t) inputTokens \(inputT)")
                    }
                    if let outputT = result.usage?.outputTokens {
                        print("type: \(t) outputTokens \(outputT)")
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
                
        func updateWordCount(isEaten: Bool = false) {
            Task { @MainActor in
                var words: [String]? = nil

                if let range = self.textView?.selectedTextRange,
                   let text = self.textView?.text(in: range),
                   !text.isEmpty {
                    words = text.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                } else 
                if let text = self.textView?.precedingText() {
                    if isEaten {
                        let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                        words = uneaten.components(separatedBy: .whitespacesAndNewlines)
                            .filter { !$0.isEmpty }
                    } else {
                        words = text.components(separatedBy: .whitespacesAndNewlines)
                            .filter { !$0.isEmpty }
                    }
                }
                if let words {
                    self.wordCount = words.count
                }
            }
        }
    }
//}
