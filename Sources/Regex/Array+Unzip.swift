extension Array {
    func unzip<S1, S2>() -> ([S1], [S2]) where Element == (S1, S2) {
        var s1: [S1] = []
        var s2: [S2] = []
        s1.reserveCapacity(self.count)
        s2.reserveCapacity(self.count)

        let _ = self.map { s1.append($0.0); s2.append($0.1) }
        return (s1, s2)
    }
}
