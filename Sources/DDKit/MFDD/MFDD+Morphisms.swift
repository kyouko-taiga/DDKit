public protocol MFDDSaturable {

  associatedtype LowestRelevantKey: Comparable

  /// The lowest key on which this morphism operates.
  ///
  /// This property is used to generate the saturated (i.e. optimized) version of a given morphism.
  var lowestRelevantKey: LowestRelevantKey { get }

}

extension MFDD {

  // TODO: InsertValueForKeys
  public final class Insert: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The assignments inserted by this morphism.
    public let assignments: [(key: Key, value: Value)]

    /// The next morphism to apply once the first assignment has been processed.
    private var next: SaturatedMorphism<Insert>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { assignments.min(by: { a, b in a.key < b.key })!.key }

    init(assignments: [(key: Key, value: Value)], factory: MFDDFactory<Key, Value>) {
      assert(!assignments.isEmpty, "Sequence of assignments to insert is empty.")
      assert(
        !assignments.containsDuplicate(identifyingElementsWith: { a in a.key }),
        "Sequence of assignments to insert contains duplicate keys.")

      self.assignments = assignments.sorted(by: { a, b in a.key < b.key })
      self.next = assignments.count > 1
        ? factory.morphisms.saturate(
          factory.morphisms.insert(assignments: self.assignments.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard pointer != factory.zeroPointer
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer == factory.onePointer {
        result = factory.encode(family: [assignments]).pointer
      } else if pointer.pointee.key < assignments[0].key {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == assignments[0].key {
        var take = pointer.pointee.take
        if let tail = pointer.pointee.take[assignments[0].value] {
          take[assignments[0].value] = factory.union(tail, pointer.pointee.skip)
        } else {
          take[assignments[0].value] = take.values.reduce(pointer.pointee.skip, factory.union)
        }

        result = factory.node(
          key: pointer.pointee.key,
          take: next != nil ? take.mapValues(next!.apply(on:)) : take,
          skip: factory.zeroPointer)
      } else {
        result = factory.node(
          key: assignments[0].key,
          take: [assignments[0].value: next?.apply(on: pointer) ?? pointer],
          skip: factory.zeroPointer)
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      for (key, value) in assignments {
        hasher.combine(key)
        hasher.combine(value)
      }
    }

    public static func == (lhs: Insert, rhs: Insert) -> Bool {
      lhs === rhs
    }

  }

  public final class RemoveKeys: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The keys removed by this morphism.
    public let keys: [Key]

    /// The next morphism to apply once the first assignment has been processed.
    private var next: RemoveKeys?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { keys.min()! }

    init(keys: [Key], factory: MFDDFactory<Key, Value>) {
      assert(!keys.isEmpty, "Sequence of keys to remove is empty.")

      self.keys = keys.sorted()
      self.next = keys.count > 1
        ? factory.morphisms.uniquify(
            RemoveKeys(keys: Array(self.keys.dropFirst()), factory: factory))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < keys[0] {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == keys[0] {
        let tail = pointer.pointee.take.values.reduce(pointer.pointee.skip, factory.union)
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

    public static func == (lhs: RemoveKeys, rhs: RemoveKeys) -> Bool {
      return lhs === rhs
    }

  }

  public final class RemoveValuesForKeys: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The assignments removed by this morphism.
    public let assignments: [(key: Key, values: [Value])]

    /// The next morphism to apply once the first assignment has been processed.
    private var next: RemoveValuesForKeys?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { assignments.min(by: { a, b in a.key < b.key })!.key }

    init(assignments: [(key: Key, values: [Value])], factory: MFDDFactory<Key, Value>) {
      assert(!assignments.isEmpty, "Sequence of assignments to remove is empty.")
      assert(
        !assignments.containsDuplicate(identifyingElementsWith: { a in a.key }),
        "Sequence of assignments to remove contains duplicate keys.")

      self.assignments = assignments.sorted(by: { a, b in a.key < b.key })
      self.next = assignments.count > 1
        ? factory.morphisms.remove(valuesForKeys: self.assignments.dropFirst())
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < assignments[0].key {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == assignments[0].key {
        var take = pointer.pointee.take
        var skip = pointer.pointee.skip

        for value in assignments[0].values {
          if let tail = pointer.pointee.take[value] {
            take[value] = nil
            skip = factory.union(skip, tail)
          }
        }

        result = factory.node(
          key: pointer.pointee.key,
          take: next != nil ? take.mapValues(next!.apply(on:)) : take,
          skip: next?.apply(on: skip) ?? skip)
      } else {
        result = next?.apply(on: pointer) ?? pointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      for (key, values) in assignments {
        hasher.combine(key)
        hasher.combine(values)
      }
    }

    public static func == (lhs: RemoveValuesForKeys, rhs: RemoveValuesForKeys) -> Bool {
      lhs === rhs
    }

  }

  public final class InclusiveFilter: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The assignments filtered by this morphism.
    public let assignments: [(key: Key, values: [Value])]

    /// The next morphism to apply once the first assignment has been processed.
    private var next: SaturatedMorphism<InclusiveFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { assignments.min(by: { a, b in a.key < b.key })!.key }

    init(assignments: [(key: Key, values: [Value])], factory: MFDDFactory<Key, Value>) {
      assert(!assignments.isEmpty, "Sequence of assignments to filter is empty.")
      assert(
        !assignments.containsDuplicate(identifyingElementsWith: { a in a.key }),
        "Sequence of assignments to filter contains duplicate keys.")

      self.assignments = assignments.sorted(by: { a, b in a.key < b.key })
      self.next = assignments.count > 1
        ? factory.morphisms.saturate(
          factory.morphisms.filter(containing: self.assignments.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return factory.zeroPointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < assignments[0].key {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == assignments[0].key {
        var take: [Value: MFDD.Pointer] = [:]
        for value in assignments[0].values {
          take[value] = pointer.pointee.take[value]
        }

        result = factory.node(
          key: pointer.pointee.key,
          take: next != nil ? take.mapValues(next!.apply(on:)) : take,
          skip: factory.zeroPointer)
      } else {
        result = factory.zeroPointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      for (key, values) in assignments {
        hasher.combine(key)
        hasher.combine(values)
      }
    }

    public static func == (lhs: InclusiveFilter, rhs: InclusiveFilter) -> Bool {
      lhs === rhs
    }

  }

  public final class ExclusiveFilter: Morphism, MFDDSaturable {

    public typealias DD = MFDD

    /// The assignments filtered by this morphism.
    public let assignments: [(key: Key, values: [Value])]

    /// The next morphism to apply once the first assignment has been processed.
    private var next: SaturatedMorphism<ExclusiveFilter>?

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key { assignments.min(by: { a, b in a.key < b.key })!.key }

    init(assignments: [(key: Key, values: [Value])], factory: MFDDFactory<Key, Value>) {
      assert(!assignments.isEmpty, "Sequence of assignments to filter is empty.")
      assert(
        !assignments.containsDuplicate(identifyingElementsWith: { a in a.key }),
        "Sequence of assignments to filter contains duplicate keys.")

      self.assignments = assignments.sorted(by: { a, b in a.key < b.key })
      self.next = assignments.count > 1
        ? factory.morphisms.saturate(
          factory.morphisms.filter(excluding: self.assignments.dropFirst()))
        : nil

      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      // Apply the morphism.
      let result: MFDD.Pointer
      if pointer.pointee.key < assignments[0].key {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
          skip: apply(on: pointer.pointee.skip))
      } else if pointer.pointee.key == assignments[0].key {
        var take: [Value: MFDD.Pointer] = pointer.pointee.take
        for value in assignments[0].values {
          take[value] = nil
        }

        result = factory.node(
          key: pointer.pointee.key,
          take: next != nil ? take.mapValues(next!.apply(on:)) : take,
          skip: next?.apply(on: pointer.pointee.skip) ?? pointer.pointee.skip)
      } else {
        result = factory.zeroPointer
      }

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      for (key, values) in assignments {
        hasher.combine(key)
        hasher.combine(values)
      }
    }

    public static func == (lhs: ExclusiveFilter, rhs: ExclusiveFilter) -> Bool {
      lhs === rhs
    }

  }

  public final class MapValues: Morphism {

    public typealias DD = MFDD

    /// The function that transforms each value.
    public let transform: (Value) -> Value

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    init(factory: MFDDFactory<Key, Value>, transform: @escaping (Value) -> Value) {
      self.transform = transform
      self.factory = factory
    }
    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Check for trivial cases.
      guard !factory.isTerminal(pointer)
        else { return pointer }

      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      let take = Dictionary(
        uniqueKeysWithValues: pointer.pointee.take.map({ (value, pointer) in
          (transform(value), pointer)
        }))
      let result = factory.node(
        key: pointer.pointee.key,
        take: take.mapValues(apply(on:)),
        skip: apply(on: pointer.pointee.skip))

      cache[pointer] = result
      return result
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: MapValues, rhs: MapValues) -> Bool {
      lhs === rhs
    }

  }

  public final class SaturatedMorphism<M>: Morphism, SFDDSaturable
    where M: Morphism, M.DD == MFDD
  {

    public typealias DD = MFDD

    // The morphism to apply after diving to the given key.
    public let morphism: M

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    public var lowestRelevantKey: Key

    init(lowestRelevantKey: Key, morphism: M, factory: MFDDFactory<Key, Value>) {
      self.lowestRelevantKey = lowestRelevantKey
      self.morphism = morphism
      self.factory = factory
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
      // Query the cache.
      if let result = cache[pointer] {
        return result
      }

      let result: MFDD.Pointer
      if pointer == factory.zeroPointer || pointer == factory.onePointer {
        result = morphism.apply(on: pointer)
      } else if pointer.pointee.key < lowestRelevantKey {
        result = factory.node(
          key: pointer.pointee.key,
          take: pointer.pointee.take.mapValues(apply(on:)),
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

  public final class Inductive: Morphism {

    public typealias DD = MFDD

    public typealias Result = (
      take: [Value: (MFDD.Pointer) -> MFDD.Pointer],
      skip: (MFDD.Pointer) -> MFDD.Pointer
    )

    /// The family returned if the morphism is applied on the one terminal.
    public let substitute: MFDD

    /// The function to apply on all non-terminal nodes.
    public let function: (Inductive, MFDD.Pointer) -> Result

    /// The factory that creates the nodes handled by this morphism.
    public unowned let factory: MFDDFactory<Key, Value>

    /// The morphism's cache.
    private var cache: [MFDD.Pointer: MFDD.Pointer] = [:]

    init(
      substitute: MFDD?,
      factory: MFDDFactory<Key, Value>,
      function: @escaping (Inductive, MFDD.Pointer) -> Result)
    {
      self.substitute = substitute ?? factory.one
      self.factory = factory
      self.function = function
    }

    public func apply(on pointer: MFDD.Pointer) -> MFDD.Pointer {
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

      // For practical reasons, note that both `fn.take` and `pointer.pointee.take` are partial
      // functions over `Value` (which might represent an infinite domain). Hence, we assume that
      // `fn.take` corresponds to the identity for all values outside of its domain, and that
      // `pointer.pointee.take` corresponds to the zero terminal for all values outside of its
      // domain. The rationale behind the latter assumption derives from that the "vanishing
      // terminal" optimization removes all edges that directly point the zero terminal.
      var take = pointer.pointee.take
      for (value, morphism) in fn.take {
        if let child = take[value] {
          // This applies if both `fn.take` and `pointer.pointee.take` are defined for `value`.
          take[value] = morphism(child)
        } else {
          // This applies if `fn.take` is defined for `value` while `pointer.pointee.take` is not.
          take[value] = morphism(factory.zeroPointer)
        }
      }

      let result = factory.node(
        key: pointer.pointee.key,
        take: take,
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

}

// MARK: Factory

/// A MFDD morphism factory.
public final class MFDDMorphismFactory<Key, Value>
  where Key: Comparable & Hashable, Value: Hashable
{

  /// The morphisms created by this factory.
  private var cache: Set<AnyHashable> = []

  /// The SFDD node factory associated with this morphism factory.
  public unowned let nodeFactory: MFDDFactory<Key, Value>

  public init(nodeFactory: MFDDFactory<Key, Value>) {
    self.nodeFactory = nodeFactory
  }

  public func uniquify<M>(_ morphism: M) -> M where M: Morphism, M.DD == MFDD<Key, Value> {
    let (_, unique) = cache.insert(morphism)
    return unique
  }

  // MARK: General decision diagram morphisms

  /// The _identity_ morphism.
  public var identity = Identity<MFDD<Key, Value>>()

  /// Creates a _constant_ morphism.
  public func constant(_ value: MFDD<Key, Value>) -> Constant<MFDD<Key, Value>> {
    Constant(value: value)
  }

  /// Creates a _union_ morphism.
  public func union<M1, M2>(_ m1: M1, _ m2: M2) -> BinaryUnion<M1, M2>
  where M1: Morphism, M2: Morphism, M1.DD == MFDD<Key, Value>
  {
    let (_, morphism) = cache.insert(BinaryUnion(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _union_ morphism.
  public func union<S, M>(of morphisms: S) -> NaryUnion<M>
    where M: Morphism, M.DD == MFDD<Key, Value>, S: Sequence, S.Element == M
  {
    let (_, morphism) = cache.insert(NaryUnion(morphisms, factory: nodeFactory))
    return morphism
  }

  /// Creates an _intersection_ morphism.
  public func intersection<M1, M2>(_ m1: M1, _ m2: M2) -> BinaryIntersection<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == MFDD<Key, Value>
  {
    let (_, morphism) = cache.insert(BinaryIntersection(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _symmetric difference_ morphism.
  public func symmetricDifference<M1, M2>(_ m1: M1, _ m2: M2) -> BinarySymmetricDifference<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == MFDD<Key, Value>
  {
    let (_, morphism) = cache.insert(BinarySymmetricDifference(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _subtraction_ morphism.
  public func subtraction<M1, M2>(_ m1: M1, _ m2: M2) -> Subtraction<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == MFDD<Key, Value>
  {
    let (_, morphism) = cache.insert(Subtraction(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _composition_ morphism.
  public func composition<M1, M2>(of m1: M1, with m2: M2) -> BinaryComposition<M1, M2>
    where M1: Morphism, M2: Morphism, M1.DD == MFDD<Key, Value>
  {
    let (_, morphism) = cache.insert(BinaryComposition(m1, m2, factory: nodeFactory))
    return morphism
  }

  /// Creates a _composition_ morphism.
  public func composition<S, M>(of morphisms: S) -> NaryComposition<M>
    where M: Morphism, M.DD == MFDD<Key, Value>, S: Sequence, S.Element == M
  {
    let (_, morphism) = cache.insert(NaryComposition(morphisms, factory: nodeFactory))
    return morphism
  }

  /// Creates a _fixed point_ morphism.
  public func fixedPoint<M>(of morphism: M) -> FixedPoint<M>
    where M: Morphism, M.DD == MFDD<Key, Value>
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
  /// - Parameter assignments: A sequence with the assignments to insert.
  public func insert<S>(assignments: S) -> MFDD<Key, Value>.Insert
    where S: Sequence, S.Element == (key: Key, value: Value)
  {
    let (_, morphism) = cache.insert(
      MFDD.Insert(assignments: Array(assignments), factory: nodeFactory))
    return morphism
  }

  /// Creates a _remove_ morphism.
  ///
  /// - Parameter assignments: A sequence with the assignments to remove.
  public func remove<S>(valuesForKeys assignments: S) -> MFDD<Key, Value>.RemoveValuesForKeys
    where S: Sequence, S.Element == (key: Key, values: [Value])
  {
    let (_, morphism) = cache.insert(
      MFDD.RemoveValuesForKeys(assignments: Array(assignments), factory: nodeFactory))
    return morphism
  }

  /// Creates a _remove_ morphism.
  ///
  /// - Parameter keys: A sequence with the assignment keys to remove.
  public func remove<S>(keys: S) -> MFDD<Key, Value>.RemoveKeys
    where S: Sequence, S.Element == Key
  {
    let (_, morphism) = cache.insert(
      MFDD.RemoveKeys(keys: Array(keys), factory: nodeFactory))
    return morphism
  }

  /// Creates an _inclusive filter_ morphism.
  ///
  /// - Parameter assignments: A sequence with the assignments that the member must contain.
  public func filter<S>(containing assignments: S) -> MFDD<Key, Value>.InclusiveFilter
    where S: Sequence, S.Element == (key: Key, values: [Value])
  {
    let (_, morphism) = cache.insert(
      MFDD.InclusiveFilter(assignments: Array(assignments), factory: nodeFactory))
    return morphism
  }

  /// Creates an _exclusive filter_ morphism.
  ///
  /// - Parameter assignments: A sequence with the assignments that the member must not contain.
  public func filter<S>(excluding assignments: S) -> MFDD<Key, Value>.ExclusiveFilter
    where S: Sequence, S.Element == (key: Key, values: [Value])
  {
    let (_, morphism) = cache.insert(
      MFDD.ExclusiveFilter(assignments: Array(assignments), factory: nodeFactory))
    return morphism
  }

  /// Creates a _map values_ morphism.
  ///
  /// The transform function must preserve the values' uniqueness. In other words, for all pairs of
  /// values `x` and `y` such that `x != y`, the relation `transform(x) != transform(y)` must hold.
  public func mapValues(transform: @escaping (Value) -> Value) -> MFDD<Key, Value>.MapValues {
    MFDD.MapValues(factory: nodeFactory, transform: transform)
  }

  /// Creates an _inductive_ morphism.
  public func inductive(
    substitutingOneWith substitute: MFDD<Key, Value>? = nil,
    function: @escaping (
      MFDD<Key, Value>.Inductive,
      MFDD<Key, Value>.Pointer
    ) -> MFDD<Key, Value>.Inductive.Result
  ) -> MFDD<Key, Value>.Inductive
  {
    MFDD.Inductive(substitute: substitute, factory: nodeFactory, function: function)
  }

  // MARK: Saturation

  public typealias Saturated<M> = MFDD<Key, Value>.SaturatedMorphism<M>
    where M: Morphism, M.DD == MFDD<Key, Value>

  public func saturate<M>(_ morphism: M, to lowestRelevantKey: Key) -> Saturated<M> {
    MFDD.SaturatedMorphism(
      lowestRelevantKey: lowestRelevantKey,
      morphism: morphism,
      factory: nodeFactory)
  }

  public func saturate<M>(_ morphism: M) -> Saturated<M>
    where M: MFDDSaturable, M.LowestRelevantKey == Key
  {
    MFDD.SaturatedMorphism(
      lowestRelevantKey: morphism.lowestRelevantKey,
      morphism: morphism,
      factory: nodeFactory)
  }

  public func saturate<M>(_ morphism: Saturated<M>) -> Saturated<M> {
    morphism
  }

}

extension Array {

  func containsDuplicate<U>(identifyingElementsWith identify: (Element) -> U) -> Bool
    where U: Equatable
  {
    for i in indices {
      for j in indices where j != i {
        guard identify(self[i]) != identify(self[j])
          else { return true }
      }
    }
    return false
  }

}
