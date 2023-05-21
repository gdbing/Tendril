import SwiftUI
import HighlightedTextEditor

let betweenVs = try! NSRegularExpression(pattern: "^vvv[\\s\\S]*?\\R\\^\\^\\^$\\R?", options: [.anchorsMatchLines])
let aboveCarats = try! NSRegularExpression(pattern: "[\\s\\S]*\\^\\^\\^\\^\\R?", options: [])

struct DocumentView: View {
    @Binding var text: String

    @State var autoScrollEnabled: Bool = true
    @State var scrollToBottom: (()->Void)? = nil

    private let rules: [HighlightRule] = [
        HighlightRule(pattern: betweenVs, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
        HighlightRule(pattern: aboveCarats, formattingRules: [
            TextFormattingRule(key: .foregroundColor, value: UIColor.secondaryLabel)
        ]),
    ]

    @ScaledMetric(relativeTo: .body) var maxWidth = 720    

    var body: some View {
        HighlightedTextEditor(text: $text, highlightRules: rules + .markdown)
            .padding()
            .frame(maxWidth: maxWidth, alignment: .center)
            .font(.body)
    }
        
//    var body: some View {
//        VStack {
//            HighlightedTextEditor(text: $text, highlightRules: rules + .markdown)
//                .introspect { editor in
//                    let delegate = ScrollViewDelegate()
//                    delegate.onDrag          = { self.autoScrollEnabled = false }
//                    delegate.onBottomReached = { self.autoScrollEnabled = true }
//                    editor.textView.delegate = delegate
//                    self.scrollToBottom = { editor.textView.scrollToBottom(animated: false) }
//                }
//        }
//        .padding()
//        .frame(maxWidth: maxWidth, alignment: .center)
//    }

}

extension UIScrollView {
    func scrollToBottom(animated:Bool) {
        let offset = self.contentSize.height - self.visibleSize.height
        if offset > self.contentOffset.y {
            self.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        }
    }
}
class ScrollViewDelegate: NSObject, UITextViewDelegate {
    private var contentHeightWhenDragEnded: CGFloat?
    
    var onDrag: (()->Void)? = nil
    var onBottomReached: (()->Void)? = nil
    
    /// disable autoscroll when user starts manually scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onDrag?()
        print("drag")
    }
    
    /// resume autoscroll when user scrolls back down to bottom
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if bottomEdge >= scrollView.contentSize.height {
            onBottomReached?()
            print("end drag")
        }
        contentHeightWhenDragEnded = scrollView.contentSize.height
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        if let contentHeightWhenDragEnded = self.contentHeightWhenDragEnded,
           bottomEdge >= contentHeightWhenDragEnded {
            onBottomReached?()
            print("decel end")
        }
        contentHeightWhenDragEnded = nil
    }
    
}
