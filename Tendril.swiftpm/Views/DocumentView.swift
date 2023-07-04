import SwiftUI

struct DocumentView: View {
    @Binding var document: Document?
    var gpt: GPTifier = GPTifier()
    @State var wordCount: Int? 
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            UIKitDocumentView(document: $document, gpt: gpt, wordCount: $wordCount)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            gpt.GPTify()
                        }, label: {
                            Image(systemName: "bubble.left.fill")
                        })
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(gpt.isWriting)
                    }
                    //                ToolbarItem(placement: .automatic) {
                    //                    if let wordCount = viewModel.gpt.wordCount {
                    //                        Text("\(self.settings.model) | \(String(format: "%.1f°", self.settings.temperature)) | \(wordCount) \(wordCount == 1 ? "word " : "words")")
                    //                            .monospacedDigit()
                    //                    }
                    //                }
                }
            if let wordCount {
                Text("\(wordCount) words ")
                    .monospacedDigit()
                //                .background {
                //                    Color(UIColor.systemBackground)
                //                }
            }

        }
    }
}

struct UIKitDocumentView: UIViewRepresentable {
    @State private var textView = UITextView()
    @Binding var document: Document?
    @Binding var wordCount: Int?
    func updateWordCount() {
        DispatchQueue.global(qos: .userInitiated).async {
            let count = self.gpt.updateWordCount()
            if let count {
                DispatchQueue.main.async {
                    self.wordCount = count
                }
            }
        }

    }
    
    private var gpt: GPTifier
    
    init(document: Binding<Document?>, gpt: GPTifier, wordCount: Binding<Int?>) {
        _document = document
        self.gpt = gpt
        _wordCount = wordCount
    }
    
    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
        
    func makeUIView(context: Context) -> UITextView {
        self.gpt.textView = textView
        if let document {
            textView.text = document.readText()
        }
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.allowsEditingTextAttributes = true
        textView.isUserInteractionEnabled = true
        textView.scrollsToTop = true
        textView.backgroundColor = UIColor.systemBackground
        textView.font = UIFont.systemFont(ofSize: 18)
        self.updateWordCount()

        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let document {
            let text = document.readText()
            let greys = document.readGreyRanges()
            if text != uiView.text {
                let attrText = NSMutableAttributedString(text, greyRanges: greys)
                uiView.attributedText = attrText
                uiView.isEditable = true
                let topOffset = CGPoint(x: 0, y: 0)
                uiView.setContentOffset(topOffset, animated: false)
            }
        } else {
            uiView.text = ""
            uiView.isEditable = false
        }
        self.updateWordCount()
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if let width = proposal.width {
            let insetSize = width > maxWidth ? ((width - maxWidth) / 2) : 0.0 
            uiView.textContainerInset = UIEdgeInsets(top: 0.0,
                                                     left: insetSize, 
                                                     bottom: 300.0,
                                                     right: insetSize)
        }
        return nil // default behaviour, use proposed size
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
    class Coordinator: NSObject, UITextViewDelegate {        
        var parent: UIKitDocumentView
        
        init(_ parent: UIKitDocumentView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.document?.write(text: textView.text)
            self.parent.document?.write(greyRanges: textView.attributedText.greyRanges)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            self.parent.updateWordCount()
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            textView.setTextColor(.label)
            return true
        }        
    }
}

extension UITextView {
    func setTextColor(_ color: UIColor) {
        var attributes = self.typingAttributes
        attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
        self.typingAttributes = attributes
    }
}
