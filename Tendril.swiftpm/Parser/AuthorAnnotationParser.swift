import Foundation

struct AuthorAnnotationParser {
    private struct AuthorKeyParser {
        private struct IsHumanParser {
            static func consume(_ input: any StringProtocol) -> (isHuman: Bool, remainder: any StringProtocol)? {
                guard input.first == "@" || input.first == "&" else { return nil }
                return (isHuman: input.first == "@", remainder: input.dropFirst())
            }
        }

        private struct NameParser {
            static func consume(_ input: any StringProtocol) -> (name: String, remainder: any StringProtocol)? {
                var nameBuilder = ""
                for char in input {
                    if char == "\n" {
                        return nil
                    } else if char == ":" {
                        return (name: nameBuilder/*.trimmingCharacters(in: .whitespacesAndNewlines)*/, remainder: input.dropFirst(nameBuilder.count + 1))
//                    } else if char == "\\" {
                        // TODO: special handling for \:
                        // TODO: handle the full spec including author identifier
                    } else {
                        nameBuilder.append(char)
                    }
                }
                return nil
            }
        }
        /*
         An annotation key can consist of any characters other than a colon. Colons must be escaped as `\:` to be included in the annotation key. Annotation keys omit the leading and trailing whitespace.

         Author annotation keys consist of:

         - `@` for human authors
         - `&` for other authors
         - optionally followed by one or more spaces
         - optionally followed by author name
         - optionally followed by author identifier
         - optionally followed by author annotation session, with a format to be announced in a future version of the spec, separated from the author name either by the author identifier or a comma
         */
        // NB: author identifier is parsed as part of author name

        static func consume(_ input: any StringProtocol) -> (name: String, isHuman: Bool, remainder: any StringProtocol)? {
            var remainder = input

            guard let result = IsHumanParser.consume(remainder) else {
                return nil
            }
            let isHuman = result.isHuman
            remainder = result.remainder

            remainder = WhitespaceParser().consume(remainder) ?? remainder

            guard let result = NameParser.consume(remainder) else {
                return nil
            }
            let name = result.name
            remainder = result.remainder

            return (name: name, isHuman: isHuman, remainder: remainder)
        }
    }

    static func consume(_ input: any StringProtocol) -> (annotation: AuthorAnnotation, remainder: any StringProtocol)? {
        var remainder = input
        remainder = WhitespaceParser().consume(remainder) ?? remainder

        guard let result = AuthorKeyParser.consume(remainder) else {
            return nil
        }
        let isHuman = result.isHuman
        let name = result.name
        remainder = result.remainder

        remainder = WhitespaceParser().consume(remainder) ?? remainder

        var ranges = [NSRange]()
        while let result = RangeParser.consume(remainder) {
            ranges.append(result.range)
            remainder = result.remainder
            remainder = WhitespaceParser().consume(remainder) ?? remainder
        }

        return (annotation: AuthorAnnotation(name: name, isHuman: isHuman, ranges: ranges), remainder: remainder)
    }
}
