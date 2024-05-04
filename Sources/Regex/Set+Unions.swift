extension Set {
    static func unions(_ seq: any Sequence<Set>) -> Set {
        seq.reduce(Set()) { (res, set) in res.union(set) }
    }
}
