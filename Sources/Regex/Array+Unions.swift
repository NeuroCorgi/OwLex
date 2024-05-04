extension Array {
    func unions<T: Hashable>() -> Set<T> where Element == Set<T> {
        return Set.unions(self)
    }
}
