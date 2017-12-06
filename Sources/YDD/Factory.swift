import Hashing
import WeakSet

public class YDDFactory<Key> where Key: Comparable & Hashable {

    public init() {
        self.zero = YDD(factory: self, count: 0)
        self.uniquenessTable.insert(self.zero)
        self.one  = YDD(factory: self, count: 1)
        self.uniquenessTable.insert(self.one)
    }

    public func make<S>(_ sequences: S) -> YDD<Key>
        where S: Sequence, S.Element: Sequence, S.Element.Element == Key
    {
        return sequences.reduce(self.zero) { family, newSequence in
            let set = Set(newSequence)
            guard !set.isEmpty else {
                return family.union(self.one)
            }

            var newMember = self.one!
            for element in set.sorted().reversed() {
                newMember = self.makeNode(key: element, take: newMember, skip: self.zero)
            }
            return family.union(newMember)
        }
    }

    public func make<S>(_ sequences: S...) -> YDD<Key> where S: Sequence, S.Element == Key {
        return self.make(sequences)
    }

    public func makeNode(key: Key, take: YDD<Key>, skip: YDD<Key>) -> YDD<Key> {
        guard take !== self.zero else {
            return skip
        }

        assert(take.isTerminal || key < take.key, "invalid YDD ordering")
        assert(skip.isTerminal || key < skip.key, "invalid YDD ordering")

        let (_, result) = self.uniquenessTable.insert(
            YDD(key: key, take: take, skip: skip, factory: self),
            withCustomEquality: YDD<Key>.areEqual)
        return result
    }

    public private(set) var zero: YDD<Key>! = nil
    public private(set) var one : YDD<Key>! = nil

    var unionCache              : [CacheKey<Key>: YDD<Key>] = [:]
    var intersectionCache       : [CacheKey<Key>: YDD<Key>] = [:]
    var symmetricDifferenceCache: [CacheKey<Key>: YDD<Key>] = [:]
    var subtractionCache        : [CacheKey<Key>: YDD<Key>] = [:]
    private var uniquenessTable : WeakSet<YDD<Key>> = []

}

// MARK: Caching

enum CacheKey<Key>: Hashable where Key: Comparable & Hashable {

    case set (Set  <YDD<Key>>)
    case list(Array<YDD<Key>>)

    var hashValue: Int {
        switch self {
        case .set (let s): return s.hashValue
        case .list(let a): return hash(a.map({ $0.hashValue }))
        }
    }

    static func ==(lhs: CacheKey, rhs: CacheKey) -> Bool {
        switch (lhs, rhs) {
        case let (.set(ls) , .set(rs)) : return ls == rs
        case let (.list(la), .list(ra)): return la == ra
        default                        : return false
        }
    }

}

