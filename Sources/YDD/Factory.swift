import Hashing
import WeakSet

public let CACHE_SIZE = 1000

public class Factory<Key> where Key: Comparable & Hashable {

    public init(
        unionCacheSize              : Int = CACHE_SIZE,
        intersectionCacheSize       : Int = CACHE_SIZE,
        symmetricDifferenceCacheSize: Int = CACHE_SIZE,
        subtractionCache            : Int = CACHE_SIZE)
    {
        self.unionCache               = Cache(size: unionCacheSize)
        self.intersectionCache        = Cache(size: intersectionCacheSize)
        self.symmetricDifferenceCache = Cache(size: symmetricDifferenceCacheSize)
        self.subtractionCache         = Cache(size: subtractionCache)

        self.zero = YDD(factory: self, count: 0)
        self.uniquenessTable.insert(self.zero)
        self.one  = YDD(factory: self, count: 1)
        self.uniquenessTable.insert(self.one)
    }

    public func make<S>(_ sequence: S) -> YDD<Key> where S: Sequence, S.Element == Key {
        let set = Set(sequence)
        guard !set.isEmpty else {
            return self.one
        }

        var result = self.one!
        for element in sequence.sorted().reversed() {
            result = self.makeNode(key: element, take: result, skip: self.zero)
        }
        return result
    }

    public func make<S>(_ sequences: S) -> YDD<Key>
        where S: Sequence, S.Element: Sequence, S.Element.Element == Key
    {
        return sequences.reduce(self.zero) { family, newMember in
            family.union(self.make(newMember))
        }
    }

    public func make<S>(_ sequences: S...) -> YDD<Key> where S: Sequence, S.Element == Key {
        return self.make(sequences)
    }

    public func makeNode(key: Key, take: YDD<Key>, skip: YDD<Key>) -> YDD<Key> {
        assert(take.isTerminal || key < take.key, "invalid YDD ordering")
        assert(skip.isTerminal || key < skip.key, "invalid YDD ordering")

        guard take !== self.zero else {
            return skip
        }

        let (_, result) = self.uniquenessTable.insert(
            YDD(key: key, take: take, skip: skip, factory: self),
            withCustomEquality: YDD<Key>.areEqual)
        return result
    }

    public private(set) var zero: YDD<Key>! = nil
    public private(set) var one : YDD<Key>! = nil

    var unionCache              : Cache<Key>
    var intersectionCache       : Cache<Key>
    var symmetricDifferenceCache: Cache<Key>
    var subtractionCache        : Cache<Key>

    private var uniquenessTable: WeakSet<YDD<Key>> = []

}

// MARK: Caching

struct Cache<Key> where Key: Comparable & Hashable {

    init(size: Int) {
        self.content = Array(repeating: CacheRecord(), count: size)
    }

    subscript(lhs: YDD<Key>, rhs: YDD<Key>) -> CacheRecord<Key> {
        get {
            let h = abs(hash([lhs.hashValue, rhs.hashValue]) % self.content.count)
            return self.content[h]
        }

        set {
            let h = abs(hash([lhs.hashValue, rhs.hashValue]) % self.content.count)
            self.content[h] = newValue
        }
    }

    var content: [CacheRecord<Key>]

}

class CacheRecord<Key> where Key: Comparable & Hashable {

    var lhs   : YDD<Key>? = nil
    var rhs   : YDD<Key>? = nil
    var result: YDD<Key>? = nil

}
