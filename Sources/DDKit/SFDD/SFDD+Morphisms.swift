public protocol SFDDSaturable {

  associatedtype LowestRelevantKey: Comparable

  /// The lowest key on which this morphism operates.
  ///
  /// This property is used to generate the saturated (i.e. optimized) version of a given morphism.
  var lowestRelevantKey: LowestRelevantKey { get }

}

extension SFDD {

  public final class Insert: Morphism, SFDDSaturable {

    public typealias DD = SFDD

    /// The keys inserted by this morphism.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<Insert>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    init(keys: [Key], factory: SFDDFactory<Key>) {
      assert(!keys.isEmpty, "Sequence of keys to insert is empty.")
      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(factory.morphisms.insert(keys: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard pointer != factory.zeroPointer
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: SFDD.Pointer
      if pointer == factory.onePointer {
        result = factory.encode(family: [keys]).pointer
      } else if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: apply(on: pointer.pointee.take),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        let tail = factory.union(pointer.pointee.take, pointer.pointee.skip)
        result = factory.node(
          key: pointer.pointee.key,
          take: next?.apply(on: tail) ?? tail,
          skip: factory.zeroPointer)
      } else {
        result = factory.node(
          key: keys[0],
          take: next?.apply(on: pointer) ?? pointer,
          skip: factory.zeroPointer)
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: Insert, rhs: Insert) -> Bool {
      lhs === rhs
    }

  }

  public final class Remove: Morphism, SFDDSaturable {

    public typealias DD = SFDD

    /// The keys removed by this morphism.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<Remove>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    init(keys: [Key], factory: SFDDFactory<Key>) {
      assert(!keys.isEmpty, "Sequence of keys to remove is empty.")
      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(factory.morphisms.remove(keys: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: SFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: apply(on: pointer.pointee.take),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        let tail = factory.union(pointer.pointee.take, pointer.pointee.skip)
        result = next?.apply(on: tail) ?? tail
      } else {
        result = next?.apply(on: pointer) ?? pointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: Remove, rhs: Remove) -> Bool {
      lhs === rhs
    }

  }

  public final class InclusiveFilter: Morphism, SFDDSaturable {

    public typealias DD = SFDD

    /// The keys that should be present in the filtered members.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<InclusiveFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    init(keys: [Key], factory: SFDDFactory<Key>) {
      assert(!keys.isEmpty, "Sequence of keys to filter is empty.")
      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(factory.morphisms.filter(containing: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return factory.zeroPointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: SFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: apply(on: pointer.pointee.take),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: next?.apply(on: pointer.pointee.take) ?? pointer.pointee.take,
          skip: factory.zeroPointer)
      } else {
        result = factory.zeroPointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: InclusiveFilter, rhs: InclusiveFilter) -> Bool {
      lhs === rhs
    }

  }

  public final class ExclusiveFilter: Morphism, SFDDSaturable {

    public typealias DD = SFDD

    /// The keys that should not be present in the filtered members.
    public let keys: [Key]

    /// The next morphism to apply once the first key has been processed.
    private var next: SaturatedMorphism<ExclusiveFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    init(keys: [Key], factory: SFDDFactory<Key>) {
      assert(!keys.isEmpty, "Sequence of keys to filter is empty.")
      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.saturate(factory.morphisms.filter(excluding: self.keys.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: SFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: apply(on: pointer.pointee.take),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        result = next?.apply(on: pointer.pointee.skip) ?? pointer.pointee.skip
      } else {
        result = next?.apply(on: pointer) ?? pointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(keys)
    }

    public static func == (lhs: ExclusiveFilter, rhs: ExclusiveFilter) -> Bool {
      lhs === rhs
    }

  }

  public final class Map: Morphism {

    public typealias DD = SFDD

    /// The function that transforms each key.
    public let transform: (Key) -> Key

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    init(factory: SFDDFactory<Key>, transform: @escaping (Key) -> Key) {
      self.transform = transform
      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      let result = factory.node(
        key: transform(pointer.pointee.key),
        take: apply(on: pointer.pointee.take),
        skip: apply(on: pointer.pointee.skip))

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Map, rhs: Map) -> Bool {
      lhs === rhs
    }

  }

  public final class Inductive: Morphism {

    public typealias DD = SFDD

    public typealias Result = (
      take: (SFDD.Pointer) -> SFDD.Pointer,
      skip: (SFDD.Pointer) -> SFDD.Pointer
    )

    /// The family returned if the morphism is applied on the one terminal.
    public let substitute: SFDD

    /// The function to apply on all non-terminal nodes.
    public let function: (Inductive, SFDD.Pointer) -> Result

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    init(
      substitute: SFDD?,
      factory: SFDDFactory<Key>,
      function: @escaping (Inductive, SFDD.Pointer) -> Result)
    {
      self.substitute = substitute ?? factory.one
      self.factory = factory
      self.function = function
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Check for trivial cases.
      guard pointer != factory.zeroPointer
        else { return pointer }
      guard pointer != factory.onePointer
        else { return substitute.pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      let fn = function(self, pointer)
      let result = factory.node(
        key: pointer.pointee.key,
        take: fn.take(pointer.pointee.take),
        skip: fn.skip(pointer.pointee.skip))

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Inductive, rhs: Inductive) -> Bool {
      lhs === rhs
    }

  }

  public final class SaturatedMorphism<M>: Morphism, SFDDSaturable
    where M: Morphism, M.DD == SFDD
  {

    public typealias DD = SFDD

    // The morphism to apply after diving to the given key.
    public let morphism: M

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: SFDDFactory<Key>

    /// The morphism's cache.
    private var cache: [SFDD.Pointer: SFDD.Pointer] = [:]

    public var lowestRelevantKey: Key

    init(lowestRelevantKey: Key, morphism: M, factory: SFDDFactory<Key>) {
      self.lowestRelevantKey = lowestRelevantKey
      self.morphism = morphism
      self.factory = factory
    }

    public func apply(on pointer: SFDD.Pointer) -> SFDD.Pointer {
      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      let result: SFDD.Pointer
      if pointer == factory.zeroPointer || pointer == factory.onePointer {
        result = morphism.apply(on: pointer)
      } else if pointer.pointee.key < lowestRelevantKey {
        result = factory.node(
          key: pointer.pointee.key,
          take: apply(on: pointer.pointee.take),
          skip: apply(on: pointer.pointee.skip))
      } else {
        result = morphism.apply(on: pointer)
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(lowestRelevantKey)
      hasher.combine(morphism)
    }

    public static func == (lhs: SaturatedMorphism, rhs: SaturatedMorphism) -> Bool {
      lhs === rhs
    }

  }

}

// MARK: Factory

/// A SFDD morphism factory.
public final class SFDDMorphismFactory<Key> where Key: Comparable & Hashable {

  /// The morphisms created by this factory.
  private var cache: Set<AnyHashable> = []

  /// The SFDD node factory associated with this morphism factory.
  public unowned let nodeFactory: SFDDFactory<Key>

  public init(nodeFactory: SFDDFactory<Key>) {
    self.nodeFactory = nodeFactory
  }

  // MARK: General decision diagram morphisms

  /// The _identity_ morphism.
  public var identity = Identity<SFDD<Key>>()

  /// Creates a _constant_ morphism.
  public func constant(_ value: SFDD<Key>) -> Constant<SFDD<Key>> {
    Constant(value: value)
  }

  /// Creates a _union_ morphism.
  public func union<M1, M2>(_ m1: M1, _ m2: M2) -> BinaryUnion<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(BinaryUnion(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _union_ morphism.
  public func union<S, M>(of morphisms: S) -> NaryUnion<M>
    where M: Morphism, M.DD == SFDD<Key>, S: Sequence, S.Element == M
  {
    let (_, morphism) = cache.insert(NaryUnion(morphisms, factory: nodeFactory))
    return morphism
  }

  /// Creates an _intersection_ morphism.
  public func intersection<M1, M2>(_ m1: M1, _ m2: M2) -> BinaryIntersection<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(BinaryIntersection(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _symmetric difference_ morphism.
  public func symmetricDifference<M1, M2>(_ m1: M1, _ m2: M2) -> BinarySymmetricDifference<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(BinarySymmetricDifference(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _subtraction_ morphism.
  public func subtraction<M1, M2>(_ m1: M1, _ m2: M2) -> Subtraction<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(Subtraction(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _composition_ morphism.
  public func composition<M1, M2>(of m1: M1, with m2: M2) -> BinaryComposition<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(BinaryComposition(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _composition_ morphism.
  public func composition<S, M>(of morphisms: S) -> NaryComposition<M>
    where M: Morphism, M.DD == SFDD<Key>, S: Sequence, S.Element == M
  {
    let (_, morphism) = cache.insert(NaryComposition(morphisms, factory: nodeFactory))
    return morphism
  }

  /// Creates a _fixed point_ morphism.
  public func fixedPoint<M>(of morphism: M) -> FixedPoint<M>
    where M: Morphism, M.DD == SFDD<Key>
  {
    let (_, morphism) = cache.insert(FixedPoint(morphism: morphism, factory: nodeFactory))
    return morphism
  }

  /// Creates a _fixed point_ morphism.
  public func fixedPoint<M>(of morphism: FixedPoint<M>) -> FixedPoint<M> {
    morphism
  }

  // MARK: SFDD-specific morphisms

  /// Creates an _insert_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys to insert.
  public func insert<S>(keys: S) -> SFDD<Key>.Insert where S: Sequence, S.Element == Key {
    let (_, morphism) = cache.insert(SFDD.Insert(keys: Array(keys), factory: nodeFactory))
    return morphism
  }

  /// Creates an _remove_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys to remove.
  public func remove<S>(keys: S) -> SFDD<Key>.Remove where S: Sequence, S.Element == Key {
    let (_, morphism) = cache.insert(SFDD.Remove(keys: Array(keys), factory: nodeFactory))
    return morphism
  }

  /// Creates an _inclusive filter_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys that the member must contain.
  public func filter<S>(containing keys: S) -> SFDD<Key>.InclusiveFilter
    where S: Sequence, S.Element == Key
  {
    let (_, morphism) = cache.insert(SFDD.InclusiveFilter(keys: Array(keys), factory: nodeFactory))
    return morphism
  }

  /// Creates an _exclusive filter_ morphism.
  ///
  /// - Parameter keys: A sequence with the keys that the member must not contain.
  public func filter<S>(excluding keys: S) -> SFDD<Key>.ExclusiveFilter
    where S: Sequence, S.Element == Key
  {
    let (_, morphism) = cache.insert(SFDD.ExclusiveFilter(keys: Array(keys), factory: nodeFactory))
    return morphism
  }

  /// Creates a _map_ morphism.
  ///
  /// The transform function must preserve the keys' order. In other words, for all pairs of keys
  /// `x` and `y` such that `x < y`, the relation `transform(x) < transform(y)` must hold.
  public func map(transform: @escaping (Key) -> Key) -> SFDD<Key>.Map {
    SFDD.Map(factory: nodeFactory, transform: transform)
  }

  /// Creates an _inductive_ morphism.
  public func inductive(
    substitutingOneWith substitute: SFDD<Key>? = nil,
    function: @escaping (SFDD<Key>.Inductive, SFDD<Key>.Pointer) -> SFDD<Key>.Inductive.Result
  ) -> SFDD<Key>.Inductive
  {
    SFDD.Inductive(substitute: substitute, factory: nodeFactory, function: function)
  }

  // MARK: Saturation

  public typealias Saturated<M> = SFDD<Key>.SaturatedMorphism<M>
    where M: Morphism, M.DD == SFDD<Key>

  public func saturate<M>(_ morphism: M, to lowestRelevantKey: Key) -> Saturated<M> {
    SFDD.SaturatedMorphism(
      lowestRelevantKey: lowestRelevantKey,
      morphism: morphism,
      factory: nodeFactory)
  }

  public func saturate<M>(_ morphism: M) -> Saturated<M>
    where M: SFDDSaturable, M.LowestRelevantKey == Key
  {
    SFDD.SaturatedMorphism(
      lowestRelevantKey: morphism.lowestRelevantKey,
      morphism: morphism,
      factory: nodeFactory)
  }

  public func saturate<M>(_ morphism: Saturated<M>) -> Saturated<M> {
    morphism
  }

//  public func saturate<M1, M2>(_ morphism: BinaryUnion<M1, M2>) -> BinaryUnion<Saturated<M1>, M2>
//    where M1: SFDDSaturable, M1.LowestRelevantKey == Key, M2: Morphism, M2.DD == SFDD<Key>
//  {
//    union(saturate(morphism.m1), morphism.m2)
//  }
//
//  public func saturate<M1, M2>(_ morphism: BinaryUnion<M1, M2>) -> BinaryUnion<M1, Saturated<M2>>
//    where M2: SFDDSaturable, M2.LowestRelevantKey == Key, M1: Morphism, M1.DD == SFDD<Key>
//  {
//    union(morphism.m1, saturate(morphism.m2))
//  }
//
//  public func saturate<M1, M2>(_ morphism: BinaryUnion<M1, M2>)
//    -> Saturated<BinaryUnion<Saturated<M1>, Saturated<M2>>>
//    where
//    M1: SFDDSaturable, M1.LowestRelevantKey == Key, M2: SFDDSaturable, M2.LowestRelevantKey == Key,
//    M1: Morphism, M1.DD == SFDD<Key>, M2: Morphism, M2.DD == SFDD<Key>
//  {
//    saturate(
//      union(saturate(morphism.m1), saturate(morphism.m2)),
//      to: Swift.min(morphism.m1.lowestRelevantKey, morphism.m2.lowestRelevantKey))
//  }

}
