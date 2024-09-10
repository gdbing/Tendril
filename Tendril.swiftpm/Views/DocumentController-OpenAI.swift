import SwiftUI
import SwiftOpenAI

fileprivate let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
fileprivate let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

extension DocumentController {

    func streamChatGPT() {
        guard !self.isWriting, let textView else { return }
        guard let text = textView.precedingText() else { return } // get text before selection
        guard let neededWords = self.omitNeedlessWords(text) else { return } // remove commented out text
        guard let queries = self.massage(text: neededWords) else { return } // convert text into messages

        let settings = Settings()
        let messages = [(role: "system", content: settings.systemMessage)] + queries

//            for message in messages {
//                print("""
//                         role: \(message.role)
//                      content: \(message.content)
//
//                      """)
//            }
        let openAiMessages = messages.map { chatMessage in
            ChatCompletionParameters.Message.init(role: ChatCompletionParameters.Message.Role(rawValue: chatMessage.role) ?? .user, content: .text(chatMessage.content))
        }

        let service = OpenAIServiceFactory.service(apiKey: settings.apiKey)

//            chatGPT.model = settings.model
//            chatGPT.temperature = Float(settings.temperature)
//
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

            let parameters = ChatCompletionParameters(messages: openAiMessages, model: .gpt4o, temperature: settings.temperature)
            let stream = try await service.startStreamedChat(parameters: parameters)
            for try await result in stream {
                if let content = result.choices.first?.delta.content {
                    textView.insertText(content)
                }
            }

        }
    }
}
