import WeakSet

public class MFDDFactory<Key, Value> where Key: Comparable & Hashable, Value: Hashable {

  public typealias Node = MFDD<Key, Value>

  public init() {
    self.zero = MFDD(factory: self, count: 0)
    self.uniquenessTable.insert(self.zero)
    self.one  = MFDD(factory: self, count: 1)
    self.uniquenessTable.insert(self.one)
  }

  public func make<S>(_ sequences: S) -> Node where S: Sequence, S.Element == [Key: Value] {
    return sequences.reduce(self.zero) { family, newMap in
      guard !newMap.isEmpty else {
        return family.union(self.one)
      }

      var newMember = self.one!
      for key in newMap.keys.sorted().reversed() {
        newMember = self.makeNode(key: key, take: [newMap[key]!: newMember], skip: self.zero)
      }
      return family.union(newMember)
    }
  }

  public func make(_ elements: [Key: Value]...) -> Node {
    return self.make(elements)
  }

  public func makeNode(key: Key, take: [Value: Node], skip: Node) -> Node {
    let nonZeroTake = take.filter({ $0.value !== self.zero })
    guard !nonZeroTake.isEmpty else {
      return skip
    }

    assert(
      nonZeroTake.values.filter({ !$0.isTerminal && (key > $0.key) }).isEmpty,
      "invalid MFDD ordering")
    assert(skip.isTerminal || key < skip.key, "invalid MFDD ordering")

    let (_, result) = self.uniquenessTable.insert(
      MFDD(key: key, take: nonZeroTake, skip: skip, factory: self),
      withCustomEquality: Node.areEqual)
    return result
  }

  public private(set) var zero: Node! = nil
  public private(set) var one : Node! = nil

  var unionCache              : [CacheKey<Key, Value>: Node] = [:]
  var intersectionCache       : [CacheKey<Key, Value>: Node] = [:]
  var symmetricDifferenceCache: [CacheKey<Key, Value>: Node] = [:]
  var subtractionCache        : [CacheKey<Key, Value>: Node] = [:]
  private var uniquenessTable : WeakSet<Node> = []

}

// MARK: Caching

enum CacheKey<Key, Value>: Hashable where Key: Comparable & Hashable, Value: Hashable {

  case set (Set  <MFDD<Key, Value>>)
  case list(Array<MFDD<Key, Value>>)

}
