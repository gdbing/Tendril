import SwiftUI
import Introspect

struct DocumentView: View {
    @Binding var text: String
    @Binding var uiTextView: UITextView?
        
    @ScaledMetric(relativeTo: .body) var maxWidth = 680    
    
    var body: some View {
            TextEditor(text: $text)
                .frame(maxWidth: maxWidth, alignment: .center)
                .introspectTextView { textView in
                    self.uiTextView = textView
                }
        }
}
