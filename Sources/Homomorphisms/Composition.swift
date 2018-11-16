public class Composition<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public init<T>(_ homomorphisms: T, factory: HomomorphismFactory<S>)
    where T: Sequence, T.Element: Homomorphism<S>
  {
    var homs: [Homomorphism<S>] = []
    for phi in homomorphisms {
      if let composition = phi as? Composition {
        homs.append(contentsOf: composition.homomorphisms)
      } else {
        homs.append(phi)
      }
    }
    self.homomorphisms = homs
    super.init(factory: factory)
  }

  public let homomorphisms: [Homomorphism<S>]

  public override func applyUncached(on s: S) -> S {
    return self.homomorphisms.reduce(s, { result, phi in phi.apply(on: result) })
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return (other as? Composition).map {
      self.homomorphisms == $0.homomorphisms
    } ?? false
  }

  public func hash(into hasher: inout Hasher) {
    for phi in homomorphisms {
      hasher.combine(phi)
    }
  }

  public override func composed(with rhs: Homomorphism<S>) -> Composition<S> {
    return factory.makeComposition([rhs] + homomorphisms)
  }

  public func composed(with rhs: Composition) -> Composition {
    return factory.makeComposition(rhs.homomorphisms + homomorphisms)
  }

}
