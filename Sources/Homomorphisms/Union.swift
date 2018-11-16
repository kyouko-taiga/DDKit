public final class Union<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public init<T>(_ homomorphisms: T, factory: HomomorphismFactory<S>)
    where T: Sequence, T.Element == Homomorphism<S>
  {
    var homs: Set<Homomorphism<S>> = []
    for phi in homomorphisms {
      if let union = phi as? Union {
        homs.formUnion(union.homomorphisms)
      } else {
        homs.insert(phi)
      }
    }
    self.homomorphisms = homs
    super.init(factory: factory)
  }

  public let homomorphisms: Set<Homomorphism<S>>

  public override func applyUncached(on s: S) -> S {
    guard !self.homomorphisms.isEmpty else { return s }
    let results = self.homomorphisms.map({ $0.apply(on: s) })
    return results.first!.union(results.dropFirst())
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return (other as? Union).map {
      self.homomorphisms == $0.homomorphisms
    } ?? false
  }

  public override var hashValue: Int {
    return self.homomorphisms.hashValue
  }

  public static func |(lhs: Union, rhs: Homomorphism<S>) -> Union {
    return lhs.factory.makeUnion(lhs.homomorphisms.union([rhs]))
  }

  public static func |(lhs: Homomorphism<S>, rhs: Union) -> Union {
    return lhs.factory.makeUnion(rhs.homomorphisms.union([lhs]))
  }

  public static func |(lhs: Union, rhs: Union) -> Union {
    return lhs.factory.makeUnion(lhs.homomorphisms.union(rhs.homomorphisms))
  }

}
