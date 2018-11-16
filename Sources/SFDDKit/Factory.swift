import WeakSet

public class Factory<Key> where Key: Comparable & Hashable {

  public init() {
    self.zero = SFDD(factory: self, count: 0)
    self.uniquenessTable.insert(self.zero)
    self.one  = SFDD(factory: self, count: 1)
    self.uniquenessTable.insert(self.one)
  }

  public func make<S>(_ sequences: S) -> SFDD<Key>
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

  public func make<S>(_ sequences: S...) -> SFDD<Key> where S: Sequence, S.Element == Key {
    return self.make(sequences)
  }

  public func makeNode(key: Key, take: SFDD<Key>, skip: SFDD<Key>) -> SFDD<Key> {
    guard take !== self.zero else {
      return skip
    }

    assert(take.isTerminal || key < take.key, "invalid SFDD ordering")
    assert(skip.isTerminal || key < skip.key, "invalid SFDD ordering")

    let (_, result) = self.uniquenessTable.insert(
      SFDD(key: key, take: take, skip: skip, factory: self),
      withCustomEquality: SFDD<Key>.areEqual)
    return result
  }

  public private(set) var zero: SFDD<Key>! = nil
  public private(set) var one : SFDD<Key>! = nil

  var unionCache              : [CacheKey<Key>: SFDD<Key>] = [:]
  var intersectionCache       : [CacheKey<Key>: SFDD<Key>] = [:]
  var symmetricDifferenceCache: [CacheKey<Key>: SFDD<Key>] = [:]
  var subtractionCache        : [CacheKey<Key>: SFDD<Key>] = [:]
  private var uniquenessTable : WeakSet<SFDD<Key>> = []

}

// MARK: Caching

enum CacheKey<Key>: Hashable where Key: Comparable & Hashable {

  case set (Set  <SFDD<Key>>)
  case list(Array<SFDD<Key>>)

  static func ==(lhs: CacheKey, rhs: CacheKey) -> Bool {
    switch (lhs, rhs) {
    case let (.set(ls) , .set(rs)) : return ls == rs
    case let (.list(la), .list(ra)): return la == ra
    default                        : return false
    }
  }

}

