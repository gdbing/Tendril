import Foundation

/*
 ---
 Annotations: 0,6310 SHA-256 0650af9e723d7401b1a63e81582eb7bd
 @Anton Sotkov: 15 20,107 128,186 490,642 1319 1562,632 2197,29 2227,18 2267,356 2624,15 2680,19 2705,21 2732,14 2752,4 2764,2846 5611,699
 @Oliver Reichenstein: 314,176
 @Iain Humm: 2194,3 2226 2245,22 2623 2639,40 2699,6 2726,6 2746,6 2756,8 5610
 ...
 */

struct AnnotationBlockParser {
    static func consume(_ input: any StringProtocol) -> (hashAnnotation: HashAnnotation,
                                                         authorAnnotations: [AuthorAnnotation],
                                                         remainder: any StringProtocol)? {
        var remainder = input
        
        guard let result = CharacterSequenceParser("---\n").consume(remainder) else {
            return nil
        }
        remainder = result

        guard let result = HashAnnotationParser.consume(remainder) else {
            return nil
        }
        let hashAnnotation = result.annotation
        remainder = result.remainder

        remainder = WhitespaceParser().consume(remainder) ?? remainder

        var authorAnnotations = [AuthorAnnotation]()
        while let result = AuthorAnnotationParser.consume(remainder) {
            authorAnnotations.append(result.annotation)
            remainder = result.remainder
            remainder = WhitespaceParser().consume(remainder) ?? remainder
        }

        guard let result = CharacterSequenceParser("...").consume(remainder) else {
            return nil
        }
        remainder = result

        guard remainder.count == 0 || remainder.hasPrefix("\n") else {
            return nil
        }

        return (hashAnnotation: hashAnnotation,
                authorAnnotations: authorAnnotations,
                remainder: remainder)
    }
}
