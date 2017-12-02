import Hashing

infix   operator °: NilCoalescingPrecedence
postfix operator *

public protocol ImmutableSetAlgebra: Hashable {

    func union       (_ other: Self) -> Self
    func intersection(_ other: Self) -> Self

}

extension Set: ImmutableSetAlgebra {}

open class Homomorphism<S>: Hashable where S: ImmutableSetAlgebra {

    public init() {}

    public final func apply(on s: S) -> S {
        return self.cache.map { cache in
            if let result = cache[s] {
                return result
            } else {
                let result = self.applyUncached(on: s)
                cache[s] = result
                return result
            }
        } ?? self.applyUncached(on: s)
    }

    open func applyUncached(on s: S) -> S {
        fatalError("not implemented")
    }

    public final var cache: Cache<S>? = nil

    open var hashValue: Int {
        return 0
    }

    open static func ==(lhs: Homomorphism, rhs: Homomorphism) -> Bool {
        return lhs === rhs
    }

    public static func |(lhs: Homomorphism, rhs: Homomorphism) -> Union<S> {
        return Union([lhs, rhs])
    }

    public static func &(lhs: Homomorphism, rhs: Homomorphism) -> Intersection<S> {
        return Intersection([lhs, rhs])
    }

    public static func °(lhs: Homomorphism, rhs: Homomorphism) -> Composition<S> {
        return Composition([rhs, lhs])
    }

    public static postfix func *(phi: Homomorphism) -> FixedPoint<S> {
        return FixedPoint(phi)
    }

}

public final class Identity<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public override func applyUncached(on s: S) -> S {
        return s
    }

}

public final class Constant<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public init(_ constant: S) {
        self.constant = constant
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

    public init<T>(_ homomorphisms: T) where T: Sequence, T.Element == Homomorphism<S> {
        self.homomorphisms = Set(homomorphisms)
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
        return Union(lhs.homomorphisms.union([rhs]))
    }

    public static func |(lhs: Homomorphism<S>, rhs: Union) -> Union {
        return Union(rhs.homomorphisms.union([lhs]))
    }

    public static func |(lhs: Union, rhs: Union) -> Union {
        return Union(lhs.homomorphisms.union(rhs.homomorphisms))
    }

}

public final class Intersection<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public init<T>(_ homomorphisms: T) where T: Sequence, T.Element == Homomorphism<S> {
        self.homomorphisms = Set(homomorphisms)
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
        return Intersection(lhs.homomorphisms.union([rhs]))
    }

    public static func &(lhs: Homomorphism<S>, rhs: Intersection) -> Intersection {
        return Intersection(rhs.homomorphisms.union([lhs]))
    }

    public static func &(lhs: Intersection, rhs: Intersection) -> Intersection {
        return Intersection(lhs.homomorphisms.union(rhs.homomorphisms))
    }

}

public class Composition<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public init<T>(_ homomorphisms: T) where T: Sequence, T.Element: Homomorphism<S> {
        self.homomorphisms = Array(homomorphisms)
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
        return Composition([rhs] + lhs.homomorphisms)
    }

    public static func °(lhs: Homomorphism<S>, rhs: Composition) -> Composition {
        return Composition(rhs.homomorphisms + [lhs])
    }

    public static func °(lhs: Composition, rhs: Composition) -> Composition {
        return Composition(rhs.homomorphisms + lhs.homomorphisms)
    }

}

public final class FixedPoint<S>: Homomorphism<S> where S: ImmutableSetAlgebra {

    public init(_ phi: Homomorphism<S>) {
        self.phi = phi
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

// MARK: Caching

public class Cache<S> where S: ImmutableSetAlgebra {

    public init(size: Int) {
        self.records = Array.init(repeating: nil, count: size)
    }

    public subscript(operand: S) -> S? {
        get {
            let h = abs(operand.hashValue % self.records.count)
            if let record = self.records[h] {
                if record.operand == operand {
                    return record.result
                }
            }
            return nil
        }

        set {
            let h = abs(operand.hashValue % self.records.count)
            self.records[h] = newValue.map {
                CacheRecord(operand: operand, result: $0)
            }
        }
    }

    private var records: [CacheRecord<S>?]

}

fileprivate struct CacheRecord<S> where S: ImmutableSetAlgebra {

    let operand: S
    let result : S

}
