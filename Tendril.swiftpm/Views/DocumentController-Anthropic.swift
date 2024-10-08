import SwiftUI
import SwiftAnthropic

class DocumentController: ObservableObject {
    @Published var isWriting = false
    @Published var wordCount: Int?
    @Published var time: Int?
    @Published var cacheTokenRead: Int = 0
    @Published var cacheTokenWrite: Int = 0
    @Published var tokenInput: Int = 0
    @Published var tokenOutput: Int = 0

    public var rope: TendrilRope?
    
    private var timer: Timer?
    private func startTimer() {
        let endTime = Date().addingTimeInterval(300)
        timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let timeRemaining = endTime.timeIntervalSinceNow
            
            if timeRemaining <= 0 {
                self.time = nil
                timer.invalidate()
            }

            self.time = Int(timeRemaining)
        }
    }
    
    var textView: UITextView?

    func gptIfy(cache: Bool = false) {
        cacheTokenRead = 0
        cacheTokenWrite = 0
        tokenInput = 0
        tokenOutput = 0
        
        switch Settings().model {
        case "claude-3-opus-20240229", "claude-3-5-sonnet-20240620", "claude-3-haiku-20240307":
            streamAnthropic(cache: cache)
        case "gpt-4o", "gpt-4o-mini", "gpt-4o-2024-08-06", "gpt-4o-2024-05-13":
            streamChatGPT()
        default:
            print("invalid model selected")
        }
    }
    
    func streamAnthropic(cache: Bool = false) {
        guard !self.isWriting, let textView else { return }
        
        guard let precedingText = textView.precedingText() else { return } // get text before selection
        var anthropicMessages: [MessageParameter.Message]
        if precedingText == rope?.toString() {
            anthropicMessages = self.rope?.toAnthropicMessages(autoCache: cache) ?? []
        } else {
            let precedingRope = TendrilRope(content: precedingText)
            precedingRope.updateBlocks()
            anthropicMessages = precedingRope.toAnthropicMessages(autoCache: cache)
        }
        guard !anthropicMessages.isEmpty else { return }
        
        let settings = Settings()
        
        guard let model: SwiftAnthropic.Model = {
            switch settings.model {
            case "claude-3-opus-20240229": return .claude3Opus
            case "claude-3-5-sonnet-20240620": return .claude35Sonnet
            case "claude-3-haiku-20240307": return .claude3Haiku
            default: return nil
            }
        }() else { return }
        
        
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
            textView.setTextColor(UIColor.aiTextGray)
            //                textView.setAuthor("gray")
            
            if parameters.messages.contains(where: {
                switch $0.content {
                case .list(let objects):
                    for object in objects {
                        if case .cache = object {
                            return true
                        }
                    }
                    return false
                default:
                    return false
                }
            }) {
                self.startTimer()
            }
            
            defer {
                self.isWriting = false
                textView.isEditable = true
                textView.isSelectable = true
                textView.setTextColor(UIColor.label)
                //                    textView.setAuthor(nil)
            }
            
            let stream = try await service.streamMessage(parameters)
            for try await result in stream {
                if let content = result.delta?.text {
                    textView.insertText(content)
                }
                
                if let createdCacheTokens = result.message?.usage.cacheCreationInputTokens {
                    self.cacheTokenWrite = createdCacheTokens
                }
                if let readCacheTokens = result.message?.usage.cacheReadInputTokens {
                    self.cacheTokenRead = readCacheTokens
                }
                if let inputTokens = result.message?.usage.inputTokens {
                    self.tokenInput = inputTokens
                }
                if let outputTokens = result.usage?.outputTokens {
                    self.tokenOutput = outputTokens
                }
            }
        }
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
                //                    if isEaten {
                //                        let uneaten = text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
                //                        words = uneaten.components(separatedBy: .whitespacesAndNewlines)
                //                            .filter { !$0.isEmpty }
                //                    } else {
                words = text.components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                //                    }
            }
            if let words {
                self.wordCount = words.count
            }
        }
    }
}

fileprivate extension TendrilRope {
    func toAnthropicMessages(autoCache: Bool = false) -> [MessageParameter.Message] {
        var messages: [(content: String, type: LeafNode.BlockType?, cache: Bool)] = []
        var node: Node? = self.head
        var currentBlock: LeafNode.BlockType? = nil
        var currentContent: String = ""
        var isCurrentCache = false

        while node != nil {
            guard !node!.isComment else {
                node = node!.next as? Node
                continue
            }
            
            switch node!.type {
                
            case .userBlockOpen, .systemBlockOpen:
                if currentBlock == nil {
                    messages.append((currentContent, currentBlock, isCurrentCache))
                    currentBlock = node!.blockType
                    currentContent = ""
                    isCurrentCache = false
                }
                
            case .blockClose:
                if currentBlock != nil {
                    messages.append((currentContent, currentBlock, isCurrentCache))
                    currentBlock = nil
                    currentContent = ""
                    isCurrentCache = false
                }
                
            case .userColon:
                if currentBlock == nil {
                    messages.append((currentContent, currentBlock, isCurrentCache))
                    currentBlock = nil
                    currentContent = ""
                    isCurrentCache = false
                    let content: String
                    if node?.content?.hasPrefix("user:") == true {
                        content = String(node?.content?.dropFirst("user:".count) ?? "")
                    } else {
                        content = node!.content!
                    }
                    messages.append((content, .user, false))
                } else {
                    currentContent += node!.content!
                }
                
            case .systemColon:
                if currentBlock == nil {
                    messages.append((currentContent, currentBlock, isCurrentCache))
                    currentBlock = nil
                    currentContent = ""
                    isCurrentCache = false
                    let content = node?.content?.dropFirst("system:".count) ?? ""
                    messages.append((String(content), .user, false))
                } else {
                    currentContent += node!.content!
                }
                
            case .cache:
                isCurrentCache = true

            case .commentOpen, .commentClose:
                break

            case .none:
                currentContent += node!.content!
            }
            
            node = node!.next as? Node
        }
        
        if !currentContent.isEmpty {
            messages.append((currentContent, currentBlock, isCurrentCache))
        }

        var cacheCount = 0
        for idx in stride(from: messages.count - 1, through: 0, by: -1) {
            if messages[idx].cache {
                if cacheCount == 5 {
                    messages[idx].cache = false
                } else {
                    cacheCount += 1
                }
            }
        }
        if cacheCount < 4 && autoCache {
            for idx in stride(from: messages.count - 1, through: 0, by: -1) {
                guard cacheCount < 5 else { break }
                if !messages[idx].cache {
                    messages[idx].cache = true
                    cacheCount += 1
                }
            }
        }

        return messages.compactMap { message(content: $0.content, type: $0.type, cache: $0.cache) }
    }
    
    private func message(content: String, type: LeafNode.BlockType?, cache: Bool) -> MessageParameter.Message? {
        let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !content.isEmpty else { return nil }
        
        let role: MessageParameter.Message.Role = type != nil ? .user : .assistant // N.B. converts system messages to user messages
        if cache {
            let cache = MessageParameter.Message.Content.ContentObject.cache(.init(type: .text, text: content, cacheControl: .init(type: .ephemeral)))
            return MessageParameter.Message(role: role, content: .list([cache]))
        } else {
            let content: MessageParameter.Message.Content = .text(content)
            return MessageParameter.Message(role: role, content: content)
        }
    }
}
