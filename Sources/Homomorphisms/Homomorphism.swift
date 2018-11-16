open class Homomorphism<S>: Hashable where S: ImmutableSetAlgebra {

    public init(factory: HomomorphismFactory<S>) {
        self.factory = factory
    }

    public final func apply(on s: S) -> S {
        if let result = self.cache[s] {
            return result
        } else {
            let result    = self.applyUncached(on: s)
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

public final class Identity<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public override func applyUncached(on s: S) -> S {
        return s
    }

    public override func isEqual(to other: Homomorphism<S>) -> Bool {
        return other is Identity
    }

}

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
