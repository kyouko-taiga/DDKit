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

    public func makeDive(to key: Key, beforeApplying phi: Homomorphism<YDD<Key>>) -> Dive<Key> {
        return self.ensureUnique(Dive(to: key, beforeApplying: phi, factory: self)) as! Dive
    }

    public func makeInductive(
        substitutingOneWith substitute: YDD<Key>? = nil,
        applying fn: @escaping (Homomorphism<YDD<Key>>, YDD<Key>) -> Inductive<Key>.Result)
        -> Inductive<Key>
    {
        return self.ensureUnique(
            Inductive(factory: self, substitutingOneWith: substitute, applying: fn)) as! Inductive
    }

    public func optimize(_ phi: Homomorphism<YDD<Key>>) -> Homomorphism<YDD<Key>> {
        switch phi {
        case let h as Union<YDD<Key>>       : return self.optimize(h)
        case let h as Intersection<YDD<Key>>: return self.optimize(h)
        case let h as Composition<YDD<Key>> : return self.optimize(h)
        case let h as FixedPoint<YDD<Key>>  : return self.optimize(h)
        case let h as Insert<Key>           : return self.optimize(h)
        case let h as Remove<Key>           : return self.optimize(h)
        case let h as Filter<Key>           : return self.optimize(h)
        default                             : return phi
        }
    }

    public func optimize(_ phi: Union<YDD<Key>>) -> Homomorphism<YDD<Key>> {
        guard phi.homomorphisms.count > 1 else {
            return phi.homomorphisms.isEmpty
                ? phi
                : phi.homomorphisms.first!
        }

        let rho = self.makeUnion(phi.homomorphisms.map({ self.optimize($0) }))
        return self.highestKey(of: rho).map {
            self.makeDive(to: $0, beforeApplying: rho)
            } ?? rho
    }

    public func optimize(_ phi: Intersection<YDD<Key>>) -> Homomorphism<YDD<Key>> {
        guard phi.homomorphisms.count > 1 else {
            return phi.homomorphisms.isEmpty
                ? phi
                : phi.homomorphisms.first!
        }

        let rho = self.makeIntersection(phi.homomorphisms.map({ self.optimize($0) }))
        return self.highestKey(of: rho).map {
            self.makeDive(to: $0, beforeApplying: rho)
            } ?? rho
    }

    public func optimize(_ phi: Composition<YDD<Key>>) -> Homomorphism<YDD<Key>> {
        guard phi.homomorphisms.count > 1 else {
            return phi.homomorphisms.isEmpty
                ? phi
                : phi.homomorphisms.first!
        }

        var homs: [Homomorphism<YDD<Key>>] = []
        for hom in phi.homomorphisms {
            let optimized = self.optimize(hom)
            if let dive = optimized as? Dive, let composition = dive.phi as? Composition {
                homs.append(contentsOf: composition.homomorphisms)
            } else if let composition = optimized as? Composition {
                homs.append(contentsOf: composition.homomorphisms)
            } else {
                homs.append(optimized)
            }
        }

        var ranges: [Range<Int>] = []
        var start = 0
        for (i, hom) in homs.enumerated() {
            if !(hom is Insert) && !(hom is Remove) {
                if i - start >= 2 {
                    ranges.append(start ..< i)
                }
                start = i + 1
            }
        }
        if homs.count - start >= 2 {
            ranges.append(start ..< homs.count)
        }

        for range in ranges {
            // Sort the insert/remove homomorphisms by how deep they dive into the DD.
            let sorted = homs[range].sorted { (lhs, rhs) in
                self.highestKey(of: lhs)! < self.highestKey(of: rhs)!
            }

            // TODO: Remove cancelling pairs of `insert(x) ° remove(x)`.

            // Encapsulate homomorphisms working on close variables into `dive` homomorphisms.
            let dive = self.makeDive(
                to            : self.highestKey(of: sorted.first!)!,
                beforeApplying: self.makeComposition(sorted))

            homs[range] = [dive]
        }

        return homs.count > 1
            ? self.makeComposition(homs)
            : homs.first!
    }

    public func optimize(_ phi: FixedPoint<YDD<Key>>) -> Homomorphism<YDD<Key>> {
        let rho = self.optimize(phi.phi)
        if let union = rho as? Union<YDD<Key>> {
            let id = self.makeIdentity()
            if union.homomorphisms.contains(id) {
                return self.makeComposition(union.homomorphisms.map({
                    ($0 | id)* as Homomorphism<YDD<Key>>
                }))
            }
        }
        return self.makeFixedPoint(rho)
    }

    public func optimize(_ phi: Insert<Key>) -> Homomorphism<YDD<Key>> {
        guard phi.keys.count > 1 else { return phi }
        return self.makeDive(
            to            : phi.keys.min()!,
            beforeApplying: self.makeComposition(
                phi.keys.map({ self.makeInsert([$0]) })))
    }

    public func optimize(_ phi: Remove<Key>) -> Homomorphism<YDD<Key>> {
        guard phi.keys.count > 1 else { return phi }
        return self.makeDive(
            to            : phi.keys.min()!,
            beforeApplying: self.makeComposition(
                phi.keys.map({ self.makeRemove([$0]) })))
    }

    public func optimize(_ phi: Filter<Key>) -> Homomorphism<YDD<Key>> {
        guard phi.keys.count > 1 else { return phi }
        return self.makeDive(
            to            : phi.keys.min()!,
            beforeApplying: self.makeComposition(
                phi.keys.map({ self.makeFilter(containing: [$0]) })))
    }

    private func highestKey(of phi: Homomorphism<YDD<Key>>) -> Key? {
        switch phi {
        case let constant as Constant<YDD<Key>>:
            return constant.constant.key

        case let union as Union<YDD<Key>>:
            var result: [Key] = []
            for rho in union.homomorphisms {
                guard let k = self.highestKey(of: rho) else { return nil }
                result.append(k)
            }
            return result.min()

        case let intersection as Intersection<YDD<Key>>:
            var result: [Key] = []
            for rho in intersection.homomorphisms {
                guard let k = self.highestKey(of: rho) else { return nil }
                result.append(k)
            }
            return result.min()

        case let composition as Composition<YDD<Key>>:
            var result: [Key] = []
            for rho in composition.homomorphisms {
                guard let k = self.highestKey(of: rho) else { return nil }
                result.append(k)
            }
            return result.min()

        case let fixedPoint as FixedPoint<YDD<Key>>:
            return self.highestKey(of: fixedPoint.phi)

        case let insert as Insert<Key>:
            return insert.keys.first

        case let remove as Remove<Key>:
            return remove.keys.first

        case let filter as Filter<Key>:
            return filter.keys.first

        case let dive as Dive<Key>:
            return self.highestKey(of: dive.phi)

        default:
            return nil
        }
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

    public override func hash(into hasher: inout Hasher) {
        for key in keys {
            hasher.combine(key)
        }
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

    public override func hash(into hasher: inout Hasher) {
        for key in keys {
            hasher.combine(key)
        }
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

    public override func hash(into hasher: inout Hasher) {
        for key in keys {
            hasher.combine(key)
        }
    }

}

public final class Dive<Key>: Homomorphism<YDD<Key>> where Key: Comparable & Hashable {

    public init(
        to key: Key,
        beforeApplying phi: Homomorphism<YDD<Key>>,
        factory: YDDHomomorphismFactory<Key>)
    {
        self.key = key
        self.phi = phi
        super.init(factory: factory)
    }

    public let key: Key
    public let phi: Homomorphism<YDD<Key>>

    public override func applyUncached(on y: YDD<Key>) -> YDD<Key> {
        guard !y.isTerminal else { return y }

        let factory = y.factory

        if y.key < self.key {
            return factory.makeNode(
                key : y.key,
                take: self.apply(on: y.take),
                skip: self.apply(on: y.skip))
        } else if y.key == self.key {
            return self.phi.apply(on: y)
        } else {
            return y
        }
    }

    public override func isEqual(to other: Homomorphism<YDD<Key>>) -> Bool {
        return (other as? Dive).map {
            (self.key == $0.key) && (self.phi == $0.phi)
            } ?? false
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(phi)
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

