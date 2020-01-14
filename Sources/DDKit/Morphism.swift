/// A type that represent a morphism of a decision diagram.
///
/// A morphism is a structure-preserving map between two decision diagrams. In other words, it is
/// akin to a function that applies on a decision diagram and produces another decision diagram.
///
/// Morphisms are able to exploit the structure of the decision diagram to compute operations on
/// encoded members at once, that is without having enumerating them, in a fashion reminiscent to
/// Single Instruction, Multiple Data (SIMD) operations.
///
/// As decision diagram nodes are guaranteed unique and immutable, morphisms are typically memoized
/// for performance. Most provided morphisms have an internal cache that stores the result of each
/// application. Consequently, these morphisms must be created by a factory to guarantee their
/// uniqueness. Such factories are provided by all decision diagram factories.
///
/// Here is an example that declares an insertion homomorphism for a SFDD.
///
///     let factory = SFDDFactory<Int>()
///     let m = factory.morphisms.insert(keys: [4, 2])
///     let family = factory.encode(family: [[1, 2], [3, 4]])
///     print(m.apply(on: family))
///     // Prints "[[1, 2, 4], [2, 3, 4]]"
///
/// Combining Morphisms
/// ===================
///
/// Because they are structure-preserving operations, morphisms can be combined to form other, more
/// complex morphisms before being applied on decision diagram. In other words, the two following
/// code are equivalent. The advantage of this approach is that memoization can apply on the whole
/// operation, rather than on each morphism individually.
///
/// DDKit provides a number of operators to combine morphisms, namely the union, intersection,
/// symmetric difference (a.k.a. disjoint union), subtraction, composition and fixed point.
///
/// Conforming to the Morphism Protocol
/// ===================================
///
/// Adding the `Morphism` conformance to your type requires at least the following declarations:
///
/// - The `apply(on:)` method for computing the result of the morphism's application.
/// - The `hash(into:)` method and an equality function for the conformance to `Hashable`.
///
/// Morphisms are typically implemented as recursive functions. Hence, for the sake of performance,
/// implementations should be defined over the underlying graph node pointers (i.e. as a function
/// `(DD.Pointer) -> DD.Pointer`) rather than over the wrappers, so as to avoid unecessary
/// allocations. Nonetheless, this protocol offers a default `apply(on:)` method that accepts and
/// returns wrappers, so as to provide a friendlier top-level API.
public protocol Morphism: Hashable {

  /// The type of decision diagrams on which this morphism operates.
  associatedtype DD: DecisionDiagram

  /// Computes the application of this morphism on the given decision diagram.
  func apply(on: DD) -> DD

  /// Computes the application of this morphism on the given decision diagram pointer.
  func apply(on: DD.Pointer) -> DD.Pointer

  /// A type-erased version of this morphism.
  var typeErased: AnyMorphism<DD> { get }

}

extension Morphism {

  public func apply(on dd: DD) -> DD {
    DD(pointer: apply(on: dd.pointer), factory: dd.factory)
  }

  public var typeErased: AnyMorphism<DD> { AnyMorphism(self) }

}

/// A type-erased morphism.
///
/// The `AnyMorphism` type forwards the application function to a boxed underlying morphism, hiding
/// the latter's type. This allows you to store mixed-type morphisms in arrays, dictionaries and
/// other homogeneous collections.
///
///     let factory = SFDDFactory<Int>()
///     let m1 = factory.morphisms.insert(keys: [4, 2])
///     let m2 = factory.morphisms.remove(keys: [3])
///     let array: [Anymorphism<SFDD<Int>>] = [AnyMorphism(m1), AnyMorphism(m2)]
///
/// An instance of `AnyMorphism` retain its equality with the boxed morphism and has the same hash.
public struct AnyMorphism<DD>: Morphism where DD: DecisionDiagram {

  /// The boxed morphism.
  ///
  /// This boxed value serves to forward equality comparisons and hashing operations to the actual
  /// underlying morphism.
  private let boxed: AnyHashable

  /// The underlying morphism's application method.
  private let _apply: (DD.Pointer) -> DD.Pointer

  /// Creates a type-erased morphism that wraps the given instance.
  ///
  /// - Parameter base: The morphism to wrap.
  public init<M>(_ base: M) where M: Morphism, M.DD == DD {
    if let other = base as? AnyMorphism<DD> {
      self = other
      return
    }

    self.boxed = AnyHashable(base)
    self._apply = base.apply(on:)
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    _apply(pointer)
  }

  public func hash(into hasher: inout Hasher) {
    boxed.hash(into: &hasher)
  }

  public static func == (lhs: AnyMorphism, rhs: AnyMorphism) -> Bool {
    lhs.boxed == rhs.boxed
  }

}

/// An identity morphism.
public struct Identity<Family>: Morphism where Family: DecisionDiagram {

  public typealias DD = Family

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    pointer
  }

  public func hash(into hasher: inout Hasher) {
  }

  public static func == (lhs: Identity, rhs: Identity) -> Bool {
    true
  }

}

/// A morphism that returns the same value, regardless of its input.
public struct Constant<Family>: Morphism where Family: DecisionDiagram {

  public typealias DD = Family

  /// The family returned by this morphism.
  public let value: DD

  public func apply(on: DD.Pointer) -> DD.Pointer {
    value.pointer
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value.pointer)
  }

  public static func == (lhs: Constant, rhs: Constant) -> Bool {
    lhs.value == rhs.value
  }

}

/// A union of two morphisms.
public final class BinaryUnion<M1, M2>: Morphism
  where M1: Morphism, M2: Morphism, M1.DD == M2.DD
{

  public typealias DD = M1.DD

  /// The first morphism whose result will be combined.
  public let m1: M1

  /// The second morphism whose result will be combined.
  public let m2: M2

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(_ m1: M1, _ m2: M2, factory: DD.Factory) {
    self.m1 = m1
    self.m2 = m2
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = factory.union(m1.apply(on: pointer), m2.apply(on: pointer))
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(m1)
    hasher.combine(m2)
  }

  public static func == (lhs: BinaryUnion, rhs: BinaryUnion) -> Bool {
    lhs === rhs
  }

}

/// A union of morphisms.
public final class NaryUnion<M>: Morphism where M: Morphism {

  public typealias DD = M.DD

  /// The morphisms whose respective results will be combined.
  public let morphisms: [M]

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init<S>(_ morphisms: S, factory: DD.Factory) where S: Sequence, S.Element == M {
    self.morphisms = Array(morphisms)
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Check for trivial cases.
    guard morphisms.count > 0
      else { return pointer }
    guard morphisms.count > 1
      else { return morphisms[0].apply(on: pointer) }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = morphisms[1...].reduce(morphisms[0].apply(on: pointer), { partial, morphism in
      factory.union(partial, morphism.apply(on: pointer))
    })
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(morphisms)
  }

  public static func == (lhs: NaryUnion, rhs: NaryUnion) -> Bool {
    lhs === rhs
  }

}

/// An intersection of two morphisms.
public final class BinaryIntersection<M1, M2>: Morphism
  where M1: Morphism, M2: Morphism, M1.DD == M2.DD
{

  public typealias DD = M1.DD

  /// The first morphism whose result will be combined.
  public let m1: M1

  /// The second morphism whose result will be combined.
  public let m2: M2

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(_ m1: M1, _ m2: M2, factory: DD.Factory) {
    self.m1 = m1
    self.m2 = m2
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = factory.intersection(m1.apply(on: pointer), m2.apply(on: pointer))
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(m1)
    hasher.combine(m2)
  }

  public static func == (lhs: BinaryIntersection, rhs: BinaryIntersection) -> Bool {
    lhs === rhs
  }

}

/// An intersection of morphisms.
public final class NaryIntersection<M>: Morphism where M: Morphism {

  public typealias DD = M.DD

  /// The morphisms whose respective results will be combined.
  public let morphisms: [M]

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init<S>(_ morphisms: S, factory: DD.Factory) where S: Sequence, S.Element == M {
    self.morphisms = Array(morphisms)
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Check for trivial cases.
    guard morphisms.count > 0
      else { return pointer }
    guard morphisms.count > 1
      else { return morphisms[0].apply(on: pointer) }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = morphisms[1...].reduce(morphisms[0].apply(on: pointer), { partial, morphism in
      factory.intersection(partial, morphism.apply(on: pointer))
    })
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(morphisms)
  }

  public static func == (lhs: NaryIntersection, rhs: NaryIntersection) -> Bool {
    lhs === rhs
  }

}

/// A symmetric difference (a.k.a. disjoint union) of two morphisms.
public final class BinarySymmetricDifference<M1, M2>: Morphism
  where M1: Morphism, M2: Morphism, M1.DD == M2.DD
{

  public typealias DD = M1.DD

  /// The first morphism whose result will be combined.
  public let m1: M1

  /// The second morphism whose result will be combined.
  public let m2: M2

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(_ m1: M1, _ m2: M2, factory: DD.Factory) {
    self.m1 = m1
    self.m2 = m2
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = factory.symmetricDifference(m1.apply(on: pointer), m2.apply(on: pointer))
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(m1)
    hasher.combine(m2)
  }

  public static func == (lhs: BinarySymmetricDifference, rhs: BinarySymmetricDifference) -> Bool {
    lhs === rhs
  }

}

/// A symmetric difference (a.k.a. disjoint union) of morphisms.
public final class NarySymmetricDifference<M>: Morphism where M: Morphism {

  public typealias DD = M.DD

  /// The morphisms whose respective results will be combined.
  public let morphisms: [M]

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init<S>(_ morphisms: S, factory: DD.Factory) where S: Sequence, S.Element == M {
    self.morphisms = Array(morphisms)
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Check for trivial cases.
    guard morphisms.count > 0
      else { return pointer }
    guard morphisms.count > 1
      else { return morphisms[0].apply(on: pointer) }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = morphisms[1...].reduce(morphisms[0].apply(on: pointer), { partial, morphism in
      factory.symmetricDifference(partial, morphism.apply(on: pointer))
    })
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(morphisms)
  }

  public static func == (lhs: NarySymmetricDifference, rhs: NarySymmetricDifference) -> Bool {
    lhs === rhs
  }

}

/// A subtraction of two morphisms.
public final class Subtraction<M1, M2>: Morphism
  where M1: Morphism, M2: Morphism, M1.DD == M2.DD
{

  public typealias DD = M1.DD

  /// The first morphism whose result will be combined.
  public let m1: M1

  /// The second morphism whose result will be combined.
  public let m2: M2

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(_ m1: M1, _ m2: M2, factory: DD.Factory) {
    self.m1 = m1
    self.m2 = m2
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = factory.subtraction(m1.apply(on: pointer), m2.apply(on: pointer))
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(m1)
    hasher.combine(m2)
  }

  public static func == (lhs: Subtraction, rhs: Subtraction) -> Bool {
    lhs === rhs
  }

}

/// A composition of two morphisms.
public final class BinaryComposition<M1, M2>: Morphism
  where M1: Morphism, M2: Morphism, M1.DD == M2.DD
{

  public typealias DD = M1.DD

  /// The first morphism whose result will be combined.
  public let m1: M1

  /// The second morphism whose result will be combined.
  public let m2: M2

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(_ m1: M1, _ m2: M2, factory: DD.Factory) {
    self.m1 = m1
    self.m2 = m2
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = m1.apply(on: m2.apply(on: pointer))
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(m1)
    hasher.combine(m2)
  }

  public static func == (lhs: BinaryComposition, rhs: BinaryComposition) -> Bool {
    lhs === rhs
  }

}

/// A composition of morphisms.
public final class NaryComposition<M>: Morphism where M: Morphism {

  public typealias DD = M.DD

  /// The morphisms whose respective results will be combined.
  public let morphisms: [M]

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init<S>(_ morphisms: S, factory: DD.Factory) where S: Sequence, S.Element == M {
    self.morphisms = Array(morphisms).reversed()
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Check for trivial cases.
    guard morphisms.count > 0
      else { return pointer }
    guard morphisms.count > 1
      else { return morphisms[0].apply(on: pointer) }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result = morphisms[1...].reduce(morphisms[0].apply(on: pointer), { $1.apply(on: $0) })
    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(morphisms)
  }

  public static func == (lhs: NaryComposition, rhs: NaryComposition) -> Bool {
    lhs === rhs
  }

}

/// The fixed point of a morphism.
public final class FixedPoint<M>: Morphism where M: Morphism {

  public typealias DD = M.DD

  // The morphism for which computing the fixed point.
  public let morphism: M

  /// The factory that creates the nodes handled by this morphism.
  public unowned let factory: DD.Factory

  /// The morphism's cache.
  private var cache: [DD.Pointer: DD.Pointer] = [:]

  init(morphism: M, factory: DD.Factory) {
    self.morphism = morphism
    self.factory = factory
  }

  public func apply(on pointer: DD.Pointer) -> DD.Pointer {
    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    var result = pointer
    while true {
      let next = morphism.apply(on: result)
      if next == result {
        break
      }
      result = next
    }

    cache[pointer] = result
    return result
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(morphism)
  }

  public static func == (lhs: FixedPoint, rhs: FixedPoint) -> Bool {
    lhs.morphism == rhs.morphism
  }

}
