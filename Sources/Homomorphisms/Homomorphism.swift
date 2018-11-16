open class Homomorphism<S>: Hashable where S: ImmutableSetAlgebra {

  public init(factory: HomomorphismFactory<S>) {
    self.factory = factory
  }

  public final func apply(on s: S) -> S {
    if let result = self.cache[s] {
      return result
    } else {
      let result = self.applyUncached(on: s)
      self.cache[s] = result
      return result
    }
  }

  open func applyUncached(on s: S) -> S {
    fatalError("not implemented")
  }

  open func isEqual(to other: Homomorphism) -> Bool {
    return self === other
  }

  public func composed(with rhs: Homomorphism) -> Composition<S> {
    return factory.makeComposition([rhs, self])
  }

  public var fixed: FixedPoint<S> {
    return factory.makeFixedPoint(self)
  }

  public let factory: HomomorphismFactory<S>

  public final var cache: [S: S] = [:]

  open var hashValue: Int {
    return 0
  }

  public static func ==(lhs: Homomorphism, rhs: Homomorphism) -> Bool {
    return lhs.isEqual(to: rhs)
  }

  public static func |(lhs: Homomorphism, rhs: Homomorphism) -> Union<S> {
    return lhs.factory.makeUnion([lhs, rhs])
  }

  public static func &(lhs: Homomorphism, rhs: Homomorphism) -> Intersection<S> {
    return lhs.factory.makeIntersection([lhs, rhs])
  }

}
