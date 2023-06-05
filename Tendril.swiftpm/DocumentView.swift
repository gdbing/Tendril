import SwiftUI
import SwiftChatGPT

struct DocumentView: View {
    private var textEditor: InertTextEditor 
    init(text: Binding<String>) {
        textEditor = InertTextEditor(text: text)
    }

    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
    
    var body: some View {
        GeometryReader { geometry in
            textEditor
            .onAppear(perform: {
                if geometry.size.width > maxWidth {
                    self.textEditor.updateInsets((geometry.size.width - maxWidth) / 2)
                }
            })
            .onChange(of: geometry.size, perform: { value in
                if geometry.size.width > maxWidth {
                    self.textEditor.updateInsets((geometry.size.width - maxWidth) / 2)
                }
            })
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        self.textEditor.GPTify()
                    }, label: {
                        Image(systemName: "bubble.left")
                    })
                    .keyboardShortcut(.return, modifiers: [.command]) 
                }
            }
        }
    }
}

struct InertTextEditor: UIViewRepresentable {
    @State var textView = UITextView()
    @Binding var text: String
    let chatGPT = ChatGPT(key: "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")
    
    func makeUIView(context: Context) -> UITextView {
        let maxWidth:CGFloat = 680
        let parentWidth = textView.superview?.frame.size.width ?? 0
        let insetSize = parentWidth > maxWidth ? (parentWidth - maxWidth) / 2 : 0.0

        updateInsets(insetSize)
        textView.text = self.text
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.systemBackground
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        //        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {        
        var parent: InertTextEditor
        
        init(_ parent: InertTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }
    }
}

extension InertTextEditor {
    func updateInsets(_ insetSize: CGFloat) {
        textView.textContainerInset = UIEdgeInsets(top: 0.0,
                                               left: insetSize, 
                                               bottom: 0.0,
                                               right: insetSize)
    }
    

    func GPTify() {
        guard let uneaten = self.textView.text else {
            return
        } 
//        let uneaten = self.uiView.text.removeMatches(to: betweenVs).removeMatches(to: aboveCarats)
        DispatchQueue.main.async {
//            do {
                Task {
                    switch await self.chatGPT.streamChatText(query: uneaten) {
                    case .failure(let error):
                        self.textView.text.append("\nCommunication Error:\n\(error.description)")
                        return
                    case .success(let results):
                        for try await result in results {
                            if let result {
                                DispatchQueue.main.async {
                                    self.textView.text.append(result)
                                }
                            }
                        }
//                    }
                }
            }
        }
    }
}
