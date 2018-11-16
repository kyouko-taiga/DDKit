public final class Identity<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

  public override func applyUncached(on s: S) -> S {
    return s
  }

  public override func isEqual(to other: Homomorphism<S>) -> Bool {
    return other is Identity
  }

}
