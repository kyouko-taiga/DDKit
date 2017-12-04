import Hashing
import Homomorphisms

extension YDD: ImmutableSetAlgebra {}

public final class YDDHomomorphismFactory<Key>: Homomorphisms.HomomorphismFactory<YDD<Key>>
    where Key: Comparable & Hashable
{

    public func makeInsert<S>(_ keys: @autoclosure () -> S) -> Insert<Key>
        where S: Sequence, S.Element == Key
    {
        return self.ensureUnique(Insert(keys, factory: self)) as! Insert
    }

    public func makeRemove<S>(_ keys: @autoclosure () -> S) -> Remove<Key>
        where S: Sequence, S.Element == Key
    {
        return self.ensureUnique(Remove(keys, factory: self)) as! Remove
    }

    public func makeFilter<S>(containing keys: @autoclosure () -> S) -> Filter<Key>
        where S: Sequence, S.Element == Key
    {
        return self.ensureUnique(Filter(containing: keys, factory: self)) as! Filter
    }

    public func makeInductive(
        substitutingOneWith substitute: YDD<Key>? = nil,
        applying fn: @escaping (Homomorphism<YDD<Key>>, YDD<Key>) -> Inductive<Key>.Result)
        -> Inductive<Key>
    {
        return self.ensureUnique(
            Inductive(factory: self, substitutingOneWith: substitute, applying: fn)) as! Inductive
    }

}

public final class Insert<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(_ keys: @autoclosure () -> S, factory: YDDHomomorphismFactory<Key>)
        where S: Sequence, S.Element == Key
    {
        self.keys = Array(keys()).sorted()
        super.init(factory: factory)
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isZero && !self.keys.isEmpty else { return y }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? (self.factory as! YDDHomomorphismFactory).makeInsert(self.keys.dropFirst())
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


    public override func isEqual(to other: Homomorphism<YDD<Key>>) -> Bool {
        return (other as? Insert).map {
            self.keys == $0.keys
            } ?? false
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

}

public final class Remove<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(_ keys: @autoclosure () -> S, factory: YDDHomomorphismFactory<Key>)
        where S: Sequence, S.Element == Key
    {
        self.keys = Array(keys()).sorted()
        super.init(factory: factory)
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isTerminal && !self.keys.isEmpty else { return y }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? (self.factory as! YDDHomomorphismFactory).makeRemove(self.keys.dropFirst())
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

    public override func isEqual(to other: Homomorphism<YDD<Key>>) -> Bool {
        return (other as? Remove).map {
            self.keys == $0.keys
            } ?? false
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

}

public final class Filter<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init<S>(containing keys: @autoclosure () -> S, factory: YDDHomomorphismFactory<Key>)
        where S: Sequence, S.Element == Key
    {
        self.keys = Array(keys()).sorted()
        super.init(factory: factory)
    }

    public let keys: [Key]

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !self.keys.isEmpty else { return y }
        guard !y.isTerminal      else { return y.factory.zero }

        let factory  = y.factory
        let followup = self.keys.count > 1
            ? (self.factory as! YDDHomomorphismFactory).makeFilter(containing: self.keys.dropFirst())
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

    public override func isEqual(to other: Homomorphism<YDD<Key>>) -> Bool {
        return (other as? Filter).map {
            self.keys == $0.keys
            } ?? false
    }

    public override var hashValue: Int {
        return hash(self.keys.map({ $0.hashValue }))
    }

}

/// - Note: Swift's functions and closures aren't equatable. Therefore we can't use properties
///   to discriminate between instances of the `Inductive` homomorphism. Instead, we rely on
///   reference equality (as defined in the base class).
public final class Inductive<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public typealias Result = (take: Homomorphism<YDD<Key>>, skip: Homomorphism<YDD<Key>>)

    public init(
        factory: YDDHomomorphismFactory<Key>,
        substitutingOneWith substitute: YDD<Key>? = nil,
        applying fn: @escaping (Homomorphism<YDD<Key>>, YDD<Key>) -> Result)
    {
        self.substitute = substitute
        self.fn         = fn
        super.init(factory: factory)
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

