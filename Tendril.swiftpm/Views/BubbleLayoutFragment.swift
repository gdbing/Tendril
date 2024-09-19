/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSTextLayoutFragment subclass to draw the comment bubble.
*/

import UIKit
import CoreGraphics

class BubbleLayoutFragment: NSTextLayoutFragment {
    override var leadingPadding: CGFloat { return 0 }
    override var trailingPadding: CGFloat { return 60 }
    override var topMargin: CGFloat { return 0 }
    override var bottomMargin: CGFloat { return 0 }

    private var tightTextBounds: CGRect {
        var fragmentTextBounds = CGRect.null
        for lineFragment in textLineFragments {
            let lineFragmentBounds = lineFragment.typographicBounds
            if fragmentTextBounds.isNull {
                fragmentTextBounds = lineFragmentBounds
            } else {
                fragmentTextBounds = fragmentTextBounds.union(lineFragmentBounds)
            }
        }
        return fragmentTextBounds
    }

    // Return the bounding rect of the bubble, in the space of the first line fragment.
    private var bubbleRect: CGRect { return tightTextBounds.insetBy(dx: -10, dy: 0) }
    private var bubbleCornerRadius: CGFloat { return 4 }

    init(textElement: NSTextElement, range rangeInElement: NSTextRange?, bubbleColor: UIColor = .userBubble) {
        self.bubbleColor = bubbleColor
        super.init(textElement: textElement, range: rangeInElement)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var bubbleColor: UIColor

    private func createBubblePath(with ctx: CGContext) -> CGPath {
        let bubbleRect = self.bubbleRect
        let rect = min(bubbleCornerRadius, bubbleRect.size.height / 2.5, bubbleRect.size.width / 2.5)
        return CGPath(roundedRect: bubbleRect, cornerWidth: rect, cornerHeight: rect, transform: nil)
    }

    override var renderingSurfaceBounds: CGRect {
        return bubbleRect.union(super.renderingSurfaceBounds)
    }

    override func draw(at renderingOrigin: CGPoint, in ctx: CGContext) {
        // Draw the bubble and debug outline.
        ctx.saveGState()
        let bubblePath = createBubblePath(with: ctx)
        ctx.addPath(bubblePath)
        ctx.setFillColor(bubbleColor.cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Draw the text on top.
        super.draw(at: renderingOrigin, in: ctx)
    }
}
