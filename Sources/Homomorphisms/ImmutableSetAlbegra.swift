public protocol ImmutableSetAlgebra: Hashable {

  func union(_ other: Self) -> Self

  func intersection(_ other: Self) -> Self

}

extension ImmutableSetAlgebra {

  public func union<S>(_ others: S) -> Self where S: Sequence, S.Element == Self {
    return others.reduce(self, { $0.union($1) })
  }

  public func intersection<S>(_ others: S) -> Self where S: Sequence, S.Element == Self {
    return others.reduce(self, { $0.intersection($1) })
  }

}
