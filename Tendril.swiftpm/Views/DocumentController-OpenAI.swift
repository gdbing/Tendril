import SwiftUI
import SwiftOpenAI

extension DocumentController {
    
    func streamChatGPT() {
        guard !self.isWriting, let textView else { return }
        
        guard let precedingText = textView.precedingText() else { return } // get text before selection
        var queries: [ChatCompletionParameters.Message]
        if precedingText == rope?.toString() {
            queries = self.rope?.toOpenAIMessages() ?? []
        } else {
            let precedingRope = TendrilRope(content: precedingText)
            precedingRope.updateBlocks()
            queries = precedingRope.toOpenAIMessages()
        }
        guard !queries.isEmpty else { return }
        
        let settings = Settings()
        let messages = [ChatCompletionParameters.Message.init(role: .system, content: .text(settings.systemMessage))] + queries
        let temperature = settings.temperature
        let model: Model = {
            switch settings.model {
                
            default:
                return .gpt4o
            }
        }()
        let service = OpenAIServiceFactory.service(apiKey: settings.apiKey)
        let parameters = ChatCompletionParameters(messages: messages, model: model, temperature: temperature)
        
        Task { @MainActor in
            self.isWriting = true
            textView.isEditable = false
            textView.isSelectable = false
            textView.setTextColor(UIColor.aiTextGray)
            //            textView.setAuthor("gray")
            
            defer {
                self.isWriting = false
                textView.isEditable = true
                textView.isSelectable = true
                textView.setTextColor(UIColor.label)
                //                textView.setAuthor(nil)
            }
            
            let stream = try await service.startStreamedChat(parameters: parameters)
            for try await result in stream {
                if let content = result.choices.first?.delta.content {
                    textView.insertText(content)
                }
            }
        }
    }
}

fileprivate extension TendrilRope {
    func toOpenAIMessages() -> [ChatCompletionParameters.Message] {
        var messages: [ChatCompletionParameters.Message] = []
        var node: Node? = self.head
        var currentBlock: LeafNode.BlockType? = nil
        var currentContent: String = ""
        
        while node != nil {
            guard !node!.isComment else {
                node = node!.next as? Node
                continue
            }
            
            switch node!.type {
                
            case .userBlockOpen, .systemBlockOpen:
                if currentBlock == nil {
                    if let message = self.message(content: currentContent, type: .system) {
                        messages.append(message)
                    }
                    currentBlock = node!.blockType
                    currentContent = ""
                }
                
            case .blockClose:
                if currentBlock != nil {
                    if let message = self.message(content: currentContent, type: .user) {
                        messages.append(message)
                    }
                    currentBlock = nil
                    currentContent = ""
                }
                
            case .userColon:
                if let message = self.message(content: currentContent, type: currentBlock) {
                    messages.append(message)
                }
                currentBlock = nil
                currentContent = ""
                let content: String
                if node?.content?.hasPrefix("user:") == true {
                    content = String(node?.content?.dropFirst("user:".count) ?? "")
                } else {
                    content = node!.content!
                }
                if let message = self.message(content: String(content), type: .user) {
                    messages.append(message)
                }
                
            case .systemColon:
                if let message = self.message(content: currentContent, type: currentBlock) {
                    messages.append(message)
                }
                currentBlock = nil
                currentContent = ""
                let content = node?.content?.dropFirst("user:".count) ?? ""
                if let message = self.message(content: String(content), type: .system) {
                    messages.append(message)
                }
                
            case .cache, .commentOpen, .commentClose:
                break
                
            case .none:
                currentContent += node!.content!
            }
            
            node = node!.next as? Node
        }
        
        if !currentContent.isEmpty {
            if let message = self.message(content: currentContent, type: currentBlock) {
                messages.append(message)
            }
        }
        
        return messages
    }
    
    private func message(content: String, type: LeafNode.BlockType?) -> ChatCompletionParameters.Message? {
        let content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !content.isEmpty else { return nil }
        
        let role: ChatCompletionParameters.Message.Role = type != nil ? (type == .user ? .user : .system) : .assistant
        return ChatCompletionParameters.Message.init(role: role, content: .text(content))
    }
}
