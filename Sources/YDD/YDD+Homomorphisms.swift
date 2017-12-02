import Hashing
import Homomorphisms

extension YDD: ImmutableSetAlgebra {}

public typealias Identity    <Key: Comparable & Hashable> = Homomorphisms.Identity    <YDD<Key>>
public typealias Constant    <Key: Comparable & Hashable> = Homomorphisms.Constant    <YDD<Key>>
public typealias Union       <Key: Comparable & Hashable> = Homomorphisms.Union       <YDD<Key>>
public typealias Intersection<Key: Comparable & Hashable> = Homomorphisms.Intersection<YDD<Key>>
public typealias Composition <Key: Comparable & Hashable> = Homomorphisms.Composition <YDD<Key>>
public typealias FixedPoint  <Key: Comparable & Hashable> = Homomorphisms.FixedPoint  <YDD<Key>>

public final class Insert<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(_ keys: @autoclosure () -> S) where S: Sequence, S.Element == Key {
        self.keys = Array(keys()).sorted()
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isZero && !self.keys.isEmpty else { return y }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? Insert(self.keys.dropFirst())
            : nil

        if y.isOne {
            return factory.makeNode(
                key : self.keys.first!,
                take: followup?.apply(on: factory.one) ?? factory.one,
                skip: factory.zero)
        } else if y.key < self.keys.first! {
            return factory.makeNode(
                key : y.key,
                take: self.apply(on: y.take),
                skip: self.apply(on: y.skip))
        } else if y.key == self.keys.first! {
            return factory.makeNode(
                key : y.key,
                take: followup?.apply(on: y.take.union(y.skip)) ?? y.take.union(y.skip),
                skip: y.factory.zero)
        } else {
            return factory.makeNode(
                key : self.keys.first!,
                take: followup?.apply(on: y) ?? y,
                skip: factory.zero)
        }
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

    public static func ==(lhs: Insert, rhs: Insert) -> Bool {
        return lhs.keys == rhs.keys
    }

}

public final class Remove<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(_ keys: @autoclosure () -> S) where S: Sequence, S.Element == Key {
        self.keys = Array(keys()).sorted()
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isTerminal && !self.keys.isEmpty else { return y }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? Remove(self.keys.dropFirst())
            : nil

        if y.key < self.keys.first! {
            return factory.makeNode(
                key : y.key,
                take: self.apply(on: y.take),
                skip: self.apply(on: y.skip))
        } else if y.key == self.keys.first! {
            return followup?.apply(on: y.skip.union(y.take)) ?? y.skip.union(y.take)
        } else {
            return followup?.apply(on: y) ?? y
        }
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

    public static func ==(lhs: Remove, rhs: Remove) -> Bool {
        return lhs.keys == rhs.keys
    }

}

public final class Filter<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(containing keys: @autoclosure () -> S) where S: Sequence, S.Element == Key {
        self.keys = Array(keys()).sorted()
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !self.keys.isEmpty else { return y }
        guard !y.isTerminal      else { return y.factory.zero }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? Filter(containing: self.keys.dropFirst())
            : nil

        if y.key < self.keys.first! {
            return factory.makeNode(
                key : y.key,
                take: self.apply(on: y.take),
                skip: self.apply(on: y.skip))
        } else if y.key == self.keys.first! {
            return factory.makeNode(
                key : y.key,
                take: followup?.apply(on: y.take) ?? y.take,
                skip: factory.zero)
        } else {
            return factory.zero
        }
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

    public static func ==(lhs: Filter, rhs: Filter) -> Bool {
        return lhs.keys == rhs.keys
    }

}

/// - Note: Swift's functions and closures aren't equatable. Therefore we can't use properties
///   to discriminate between instances of the `Inductive` homomorphism. Instead, we rely on
///   reference equality (as defined in the base class).
public final class Inductive<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public typealias Result = (take: Homomorphism<YDD<Key>>, skip: Homomorphism<YDD<Key>>)

    public init(
        substitutingOneWith substitute: YDD<Key>? = nil,
        applying fn: @escaping (Homomorphism<YDD<Key>>, YDD<Key>) -> Result)
    {
        self.substitute = substitute
        self.fn         = fn
    }

    public let substitute: YDD<Key>?
    public let fn        : (Homomorphism<YDD<Key>>, YDD<Key>) -> Result

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isZero else { return y }
        guard !y.isOne  else { return self.substitute ?? y }

        let (phiTake, phiSkip) = self.fn(self, y)
        let factory = y.factory
        return factory.makeNode(
            key : y.key,
            take: phiTake.apply(on: y.take),
            skip: phiSkip.apply(on: y.skip))
    }

    public override var hashValue: Int {
        return self.substitute?.hashValue ?? 0
    }

}
