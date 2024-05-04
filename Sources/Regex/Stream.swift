struct TokenStream {
    typealias Item = Character

    private var iter: any IteratorProtocol<Item>

    var current: Item? = nil

    init(from stream: any IteratorProtocol<Item>) {
        iter = stream
        current = iter.next()
    }

    func peek() -> Item? {
        return current
    }

    mutating func next() -> Item? {
        defer { current = iter.next() }
        return current
    }
}

extension String {
    func makeTokenStream() -> TokenStream {
        return TokenStream(from: self.makeIterator())
    }
}
