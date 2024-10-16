import Foundation

struct DocumentParser {
    static func consume(_ input: any StringProtocol) -> (content: String,
                                                         hashAnnotation: HashAnnotation,
                                                         authorAnnotations: [AuthorAnnotation],
                                                         remainder: any StringProtocol)? {

        var idx = input.indices.last // annotation block is at the end, checking last indices first is a slight speedup for Moby Dick sized documents
        while idx != nil, idx != input.indices.first {
            let remainder = input.suffix(from: idx!)

            guard remainder.hasPrefix("\n\n"),
                  let result = AnnotationBlockParser.consume(remainder.dropFirst(2)) else {
                idx = input.index(idx!, offsetBy: -1)
                continue
            }
            
            let content = String(input.prefix(upTo:idx!))
            return (content: content,
                    hashAnnotation: result.hashAnnotation,
                    authorAnnotations: result.authorAnnotations,
                    remainder: result.remainder)
        }

        return nil
    }
}
