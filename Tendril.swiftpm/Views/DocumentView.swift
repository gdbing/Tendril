import SwiftUI

struct DocumentView: View {
    @StateObject var controller = DocumentController()
    @Binding var document: Document?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            UIKitDocumentView(controller: controller, 
                              document: $document)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
//                            controller.gptIfy()
                            controller.streamAnthropic()
                        }, label: {
                            Image(systemName: "bubble.left.fill")
                        })
                        .keyboardShortcut(.return, modifiers: [.command])
                        .disabled(controller.isWriting)
                    }
                }
            if let wordCount = controller.wordCount {
                Text("\(wordCount) words ")
                    .monospacedDigit()
            }
        }
    }
}

extension DocumentView {   
    struct UIKitDocumentView: UIViewRepresentable {
        var controller: DocumentController
        
        @State private var textView = UITextView()
        @Binding var document: Document?
                
        init(controller: DocumentController, document: Binding<Document?>) {
            self.controller = controller
            _document = document
        }
        
        @ScaledMetric(relativeTo: .body) var maxWidth = 680    
        
        func makeUIView(context: Context) -> UITextView {
            self.controller.textView = textView
            if let document {
                textView.becomeFirstResponder()
                textView.text = document.readText()
                controller.updateWordCount()
            }
            textView.delegate = context.coordinator
            textView.isScrollEnabled = true
            textView.isEditable = true
            textView.allowsEditingTextAttributes = true
            textView.isUserInteractionEnabled = true
            textView.scrollsToTop = true
            textView.backgroundColor = UIColor.systemBackground
            textView.font = UIFont.systemFont(ofSize: 18)
            
            return textView
        }
        
        func updateUIView(_ uiView: UITextView, context: Context) {
            self.controller.textView = uiView
            if let document {
                let text = document.readText()
                let greys = document.readGreyRanges()
                if text != uiView.text {
                    let attrText = NSMutableAttributedString(text, greyRanges: greys)
                    uiView.attributedText = attrText
                    controller.updateWordCount()
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
                self.parent.controller.updateWordCount() // this basically catches textViewDidChange too
            }
            
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                textView.setTextColor(.label)
                return true
            }        
        }
    }
}
extension UITextView {
    func setTextColor(_ color: UIColor) {
        var attributes = self.typingAttributes
        attributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
        self.typingAttributes = attributes
    }
    
    func precedingText() -> String? {
        if let selection = self.selectedTextRange,
           let precedingRange = self.textRange(from: self.beginningOfDocument, to: selection.end),
           let precedingText = self.text(in: precedingRange),
           precedingText.count > 0 {
            return precedingText
        } else {
            return nil
        }
    }
}
