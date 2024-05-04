private func parseSplit(_ stream: inout TokenStream) -> NRegex? {
    var concats: [NRegex] = []
    guard let concat = parseConcat(&stream) else {
        // Propagate error
        return nil
    }
    concats.append(concat)
    while let c = stream.peek() {
        if c == ")" { break }

        guard c == "|" else {
            // Signal error
            return nil
        }
        // print("Split")
        _ = stream.next()

        guard let concat = parseConcat(&stream) else {
            // Propagate error
            return nil
        }
        concats.append(concat)        
    }
    return alternative(concats)
}

private func parseConcat(_ stream: inout TokenStream) -> NRegex? {
    var nodes: [NRegex] = []
    while let c = stream.peek() {
        if "|)".contains(c) { break }

        guard let node = parseNode(&stream) else {
            // Propagete error
            return nil
        }
        nodes.append(node)
    }
    // print("Nodes:")
    // for node in nodes {
    //     print(node)
    // }
    // print("Result")
    let res = concatenate(nodes)
    // print(res)
    // print()
    return res
}

private func parseNode(_ stream: inout TokenStream) -> NRegex? {
    var matcher: NRegex
    switch stream.peek() {
    case "(":
        _ = stream.next()
        guard let split = parseSplit(&stream) else {
            return nil
        }
        guard stream.next() == ")" else {
            return nil
        }
        // print("Parsed braced split")
        matcher = split
    case ".":
        _ = stream.next()
        matcher = dotMatcher()
    case "\\":
        _ = stream.next()
        switch stream.next() {
        case "|":
            matcher = letterMatcher("|")
        case "\\":
            matcher = letterMatcher("\\")
        default:
            print("Unknown escape sequence")
            return nil
        }
    case let c where c != nil && !(c?.isSymbol ?? true):
        _ = stream.next()
        // print("Character: \(c!)")
        matcher = letterMatcher(c!)
    default:
        return nil
    }
    if stream.peek() == nil {
        // print("Last")
        // print(matcher)
    }
    return parsePostfix(&stream)(matcher)
}

private func parsePostfix(_ stream: inout TokenStream) -> (NRegex) -> NRegex {
    switch stream.peek() {
    case "*":
        // print("Star")
        _ = stream.next()
        return zeroOrMore
    case "+":
        // print("Plus")
        _ = stream.next()
        return oneOrMore
    default:
        // print("Identity: \(stream.peek())")
        return { $0 }
    }
}

public func parseRegex(from str: String) -> DRegex? {
    var stream = str.makeTokenStream()
    guard let nregex = parseSplit(&stream), stream.peek() == nil else {
        return nil
    }

    let dregex = DFA(from: nregex)
    return dregex.normalize()
}
