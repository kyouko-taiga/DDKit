public final class Intersection<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public init<T>(_ homomorphisms: T, factory: HomomorphismFactory<S>)
    where T: Sequence, T.Element == Homomorphism<S>
  {
    var homs: Set<Homomorphism<S>> = []
    for phi in homomorphisms {
      if let intersection = phi as? Intersection {
        homs.formIntersection(intersection.homomorphisms)
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
    return results.first!.intersection(results.dropFirst())
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return (other as? Intersection).map {
      self.homomorphisms == $0.homomorphisms
    } ?? false
  }

  public override var hashValue: Int {
    return self.homomorphisms.hashValue
  }

  public static func &(lhs: Intersection, rhs: Homomorphism<S>) -> Intersection {
    return lhs.factory.makeIntersection(lhs.homomorphisms.union([rhs]))
  }

  public static func &(lhs: Homomorphism<S>, rhs: Intersection) -> Intersection {
    return lhs.factory.makeIntersection(rhs.homomorphisms.union([lhs]))
  }

  public static func &(lhs: Intersection, rhs: Intersection) -> Intersection {
    return lhs.factory.makeIntersection(lhs.homomorphisms.union(rhs.homomorphisms))
  }

}
