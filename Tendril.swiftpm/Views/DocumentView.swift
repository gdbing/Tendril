import SwiftUI
import SwiftChatGPT

struct DocumentView: UIViewRepresentable {
    @State private var textView = UITextView()
    @Binding var document: Document?
    
    private var gpt: GPTifier
    
    init(document: Binding<Document?>, gpt: GPTifier) {
        _document = document
        self.gpt = gpt
    }
    
    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
        
    func makeUIView(context: Context) -> UITextView {
        self.gpt.textView = textView
        if let document {
            textView.text = document.read()
        }
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.scrollsToTop = true
        textView.backgroundColor = UIColor.systemBackground
        textView.font = UIFont.systemFont(ofSize: 18)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if let document {
            let documentText = document.read()
            if documentText != uiView.text {
                uiView.text = documentText
                uiView.isEditable = true
                let topOffset = CGPoint(x: 0, y: 0)
                uiView.setContentOffset(topOffset, animated: false)
            }
        } else {
            uiView.text = ""
            uiView.isEditable = false
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if let width = proposal.width {
            let insetSize = width > maxWidth ? ((width - maxWidth) / 2) : 0.0 
            uiView.textContainerInset = UIEdgeInsets(top: 0.0,
                                                     left: insetSize, 
                                                     bottom: 0.0,
                                                     right: insetSize)
        }
        return nil // default behaviour, use proposed size
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
    class Coordinator: NSObject, UITextViewDelegate {        
        var parent: DocumentView
        
        init(_ parent: DocumentView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.document?.write(text: textView.text)
            // TODO write gray
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            textView.setTextColor(.label)
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
