import Hashing

infix   operator °: NilCoalescingPrecedence
postfix operator *

public protocol ImmutableSetAlgebra: Hashable {

    func union       (_ other: Self) -> Self
    func intersection(_ other: Self) -> Self

}

extension Set: ImmutableSetAlgebra {}

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

    open let factory: HomomorphismFactory<S>

    public final var cache: [S: S] = [:]

    open var hashValue: Int {
        return 0
    }

    open static func ==(lhs: Homomorphism, rhs: Homomorphism) -> Bool {
        return lhs === rhs
    }

    public static func |(lhs: Homomorphism, rhs: Homomorphism) -> Union<S> {
        return lhs.factory.makeUnion([lhs, rhs])
    }

    public static func &(lhs: Homomorphism, rhs: Homomorphism) -> Intersection<S> {
        return lhs.factory.makeIntersection([lhs, rhs])
    }

    public static func °(lhs: Homomorphism, rhs: Homomorphism) -> Composition<S> {
        return lhs.factory.makeComposition([rhs, lhs])
    }

    public static postfix func *(phi: Homomorphism) -> FixedPoint<S> {
        return phi.factory.makeFixedPoint(phi)
    }

}

public final class Identity<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public override func applyUncached(on s: S) -> S {
        return s
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

    public override var hashValue: Int {
        return self.constant.hashValue
    }

    public static func ==(lhs: Constant, rhs: Constant) -> Bool {
        return lhs.constant == rhs.constant
    }

}

public final class Union<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public init<T>(_ homomorphisms: T, factory: HomomorphismFactory<S>)
        where T: Sequence, T.Element == Homomorphism<S>
    {
        self.homomorphisms = Set(homomorphisms)
        super.init(factory: factory)
    }

    public let homomorphisms: Set<Homomorphism<S>>

    public override func applyUncached(on s: S) -> S {
        var result = s
        var first  = true
        for phi in self.homomorphisms {
            if first {
                result = phi.apply(on: s)
                first  = false
            } else {
                result = result.union(phi.apply(on: s))
            }
        }
        return result
    }

    public override var hashValue: Int {
        return self.homomorphisms.hashValue
    }

    public static func ==(lhs: Union, rhs: Union) -> Bool {
        return lhs.homomorphisms == rhs.homomorphisms
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
        self.homomorphisms = Set(homomorphisms)
        super.init(factory: factory)
    }

    public let homomorphisms: Set<Homomorphism<S>>

    public override func applyUncached(on s: S) -> S {
        var result = s
        var first  = true
        for phi in self.homomorphisms {
            if first {
                result = phi.apply(on: s)
                first  = false
            } else {
                result = result.intersection(phi.apply(on: s))
            }
        }
        return result
    }

    public override var hashValue: Int {
        return self.homomorphisms.hashValue
    }

    public static func ==(lhs: Intersection, rhs: Intersection) -> Bool {
        return lhs.homomorphisms == rhs.homomorphisms
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
        self.homomorphisms = Array(homomorphisms)
        super.init(factory: factory)
    }

    public let homomorphisms: [Homomorphism<S>]

    public override func applyUncached(on s: S) -> S {
        return self.homomorphisms.reduce(s, { result, phi in phi.apply(on: result) })
    }

    public override var hashValue: Int {
        return hash(self.homomorphisms.map({ $0.hashValue }))
    }

    public static func ==(lhs: Composition, rhs: Composition) -> Bool {
        return lhs.homomorphisms == rhs.homomorphisms
    }

    public static func °(lhs: Composition, rhs: Homomorphism<S>) -> Composition {
        return lhs.factory.makeComposition([rhs] + lhs.homomorphisms)
    }

    public static func °(lhs: Homomorphism<S>, rhs: Composition) -> Composition {
        return lhs.factory.makeComposition(rhs.homomorphisms + [lhs])
    }

    public static func °(lhs: Composition, rhs: Composition) -> Composition {
        return lhs.factory.makeComposition(rhs.homomorphisms + lhs.homomorphisms)
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

    public override var hashValue: Int {
        return self.phi.hashValue
    }

    public static func ==(lhs: FixedPoint, rhs: FixedPoint) -> Bool {
        return lhs.phi == rhs.phi
    }

}

