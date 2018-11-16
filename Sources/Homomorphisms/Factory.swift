open class HomomorphismFactory<S> where S: ImmutableSetAlgebra {

  public init() {}

   public func ensureUnique(_ phi: Homomorphism<S>) -> Homomorphism<S> {
    let (_, result) = self.uniquenessTable.insert(phi)
    return result
  }

  open func makeIdentity() -> Identity<S> {
    return self.ensureUnique(Identity(factory: self)) as! Identity
  }

  open func makeConstant(_ constant: S) -> Constant<S> {
    return self.ensureUnique(Constant(constant, factory: self)) as! Constant
  }

  open func makeUnion<T>(_ homomorphisms: T) -> Union<S>
    where T: Sequence, T.Element == Homomorphism<S>
  {
    return self.ensureUnique(Union(homomorphisms, factory: self)) as! Union
  }

  open func makeIntersection<T>(_ homomorphisms: T) -> Intersection<S>
    where T: Sequence, T.Element == Homomorphism<S>
  {
    return self.ensureUnique(Intersection(homomorphisms, factory: self)) as! Intersection
  }

  open func makeComposition<T>(_ homomorphisms: T) -> Composition<S>
    where T: Sequence, T.Element == Homomorphism<S>
  {
    return self.ensureUnique(Composition(homomorphisms, factory: self)) as! Composition
  }

  open func makeFixedPoint(_ phi: Homomorphism<S>) -> FixedPoint<S> {
    return self.ensureUnique(FixedPoint(phi, factory: self)) as! FixedPoint
  }

  private var uniquenessTable: Set<Homomorphism<S>> = []

}

