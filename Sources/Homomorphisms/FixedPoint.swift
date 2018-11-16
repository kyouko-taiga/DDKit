public final class FixedPoint<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public init(_ phi: Homomorphism<S>, factory: HomomorphismFactory<S>) {
    self.phi = phi
    super.init(factory: factory)
  }

  public let phi: Homomorphism<S>

  public override func applyUncached(on s: S) -> S {
    var result = self.phi.apply(on: s)
    while true {
      let next = self.phi.apply(on: result)
      if next == result {
        break
      }
      result = next
    }
    return result
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return (other as? FixedPoint).map {
      self.phi == $0.phi
      } ?? false
  }

  public override var hashValue: Int {
    return self.phi.hashValue
  }

}
