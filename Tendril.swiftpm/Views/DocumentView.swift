import SwiftUI
import SwiftChatGPT

struct DocumentView: UIViewRepresentable {
    @State private var textView = UITextView()
    @Binding var text: String
    @Binding var gpt: GPTifier?
    
    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
        
    func makeUIView(context: Context) -> UITextView {
        self.gpt = GPTifier(textView)

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
        // This is not needed if `textView` is the primary source of truth, and, in fact, was the source of a ton of annoying glitches and issues when there are >500 words in the view

        // uiView.text = text
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if let width = proposal.width {
            let insetSize = width > maxWidth ? ((width - maxWidth) / 2) : 0.0 
            uiView.textContainerInset = UIEdgeInsets(top: 0.0,
                                                     left: insetSize, 
                                                     bottom: 0.0,
                                                     right: insetSize)
        }
        return nil
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
            self.parent.text = textView.text
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            self.parent.gpt?.setTextColor(.label)
//            self.parent.textView.frame.width
        }
        
        
    }
}
