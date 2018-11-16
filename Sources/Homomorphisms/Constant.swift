public final class Constant<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public init(_ constant: S, factory: HomomorphismFactory<S>) {
    self.constant = constant
    super.init(factory: factory)
  }

  public let constant: S

  public override func applyUncached(on s: S) -> S {
    return constant
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return (other as? Constant).map {
      self.constant == $0.constant
    } ?? false
  }

  public override var hashValue: Int {
    return self.constant.hashValue
  }

}
