public final class MFDD<Key, Value>: Hashable
    where Key: Comparable & Hashable, Value: Hashable
{

    public let key : Key!
    public let take: [Value: MFDD]!
    public let skip: MFDD!

    public unowned let factory: MFDDFactory<Key, Value>

    public let count: Int

    public var isZero    : Bool { return self === self.factory.zero }
    public var isOne     : Bool { return self === self.factory.one }
    public var isTerminal: Bool { return self.isZero || self.isOne }
    public var isEmpty   : Bool { return self.isZero }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(take)
        hasher.combine(skip)
        hasher.combine(count)
    }

    /// Returns `true` if these MFDDs contain the same elements.
    public static func ==(lhs: MFDD, rhs: MFDD) -> Bool {
        return lhs === rhs
    }

    /// Returns `true` if the MFDD contains the given element.
    public func contains(_ element: [Key: Value]) -> Bool {
        if element.count == 0 {
            return self.skipMost.isOne
        }

        var node = self
        var keys = element.keys.sorted()

        while !node.isTerminal && !keys.isEmpty {
            let key = keys.first!
            if key > node.key {
                node = node.skip
            } else if key == node.key {
                if let successor = node.take[element[key]!] {
                    node = successor
                    keys.removeFirst()
                } else {
                    return false
                }
            } else {
                node = node.skip
            }
        }

        return keys.isEmpty && node.skipMost.isOne
    }

    /// Returns the union of this MFDD with another one.
    public func union(_ other: MFDD) -> MFDD {
        if self.isZero || (self === other) {
            return other
        } else if other.isZero {
            return self
        }

        let cacheKey: CacheKey = .set([self, other])
        if let result = self.factory.unionCache[cacheKey] {
            return result
        }
        let result: MFDD

        if self.isOne {
            result = self.factory.makeNode(
                key : other.key,
                take: other.take,
                skip: other.skip.union(self))
        } else if other.isOne || (other.key > self.key) {
            result = self.factory.makeNode(
                key : self.key,
                take: self.take,
                skip: self.skip.union(other))
        } else if other.key == self.key {
            let newTake = self.take.map({ value, successor in
                other.take[value].map {
                    (value, successor.union($0))
                } ?? (value, successor)
            }) + other.take.compactMap({ value, successor in
                self.take[value] == nil ? (value, successor) : nil
            })

            result = self.factory.makeNode(
                key : self.key,
                take: Dictionary(uniqueKeysWithValues: newTake),
                skip: self.skip.union(other.skip))
        } else if other.key < self.key {
            result = self.factory.makeNode(
                key : other.key,
                take: other.take,
                skip: other.skip.union(self))
        } else {
            fatalError()
        }

        self.factory.unionCache[cacheKey] = result
        return result
    }

    /// Returns the intersection of this MFDD with another one.
    public func intersection(_ other: MFDD) -> MFDD {
        if self.isZero || (self === other) {
            return self
        } else if other.isZero {
            return other
        }

        let cacheKey: CacheKey = .set([self, other])
        if let result = self.factory.intersectionCache[cacheKey] {
            return result
        }
        let result: MFDD

        if self.isOne {
            result = other.skipMost
        } else if other.isOne {
            result = self.skipMost
        } else if other.key > self.key {
            result = self.skip.intersection(other)
        } else if other.key == self.key {
            let newTake = self.take.compactMap({ value, successor in
                other.take[value].map({ (value, successor.intersection($0)) })
            })

            result = self.factory.makeNode(
                key : self.key,
                take: Dictionary(uniqueKeysWithValues: newTake),
                skip: self.skip.intersection(other.skip))
        } else if other.key < self.key {
            result = self.intersection(other.skip)
        } else {
            fatalError()
        }

        self.factory.intersectionCache[cacheKey] = result
        return result
    }

    /// Returns the symmetric difference between this MFDD and another one.
    public func symmetricDifference(_ other: MFDD) -> MFDD {
        if self.isZero {
            return other
        } else if other.isZero {
            return self
        } else if (self === other) {
            return self.factory.zero
        }

        let cacheKey: CacheKey = .set([self, other])
        if let result = self.factory.symmetricDifferenceCache[cacheKey] {
            return result
        }
        let result: MFDD

        if self.isOne {
            result = self.factory.makeNode(
                key : other.key,
                take: other.take,
                skip: self.symmetricDifference(other.skip))
        } else if other.isOne || (other.key > self.key) {
            result = self.factory.makeNode(
                key : self.key,
                take: self.take,
                skip: self.skip.symmetricDifference(other))
        } else if other.key == self.key {
            let newTake = Set(self.take.keys)
                .union(other.take.keys)
                .map({ value -> (Value, MFDD<Key, Value>) in
                    let successor = self.take[value].map { lhs in
                        other.take[value].map { rhs in
                            lhs.symmetricDifference(rhs)
                        } ?? lhs
                    } ?? other.take[value]!
                    return (value, successor)
                })

            result = self.factory.makeNode(
                key : self.key,
                take: Dictionary(uniqueKeysWithValues: newTake),
                skip: self.skip.symmetricDifference(other.skip))
        } else if other.key < self.key {
            result = self.factory.makeNode(
                key : other.key,
                take: other.take,
                skip: self.symmetricDifference(other.skip))
        } else {
            fatalError()
        }

        self.factory.symmetricDifferenceCache[cacheKey] = result
        return result
    }

    /// Returns the result of subtracting another MFDD to this one.
    public func subtracting(_ other: MFDD) -> MFDD {
        if self.isZero || other.isZero {
            return self
        } else if (self === other) {
            return self.factory.zero
        }

        let cacheKey: CacheKey = .list([self, other])
        if let result = self.factory.subtractionCache[cacheKey] {
            return result
        }
        let result: MFDD

        if self.isOne {
            result = other.skipMost.isZero
                ? self
                : self.factory.zero
        } else if other.isOne  || (other.key > self.key){
            result = self.factory.makeNode(
                key : self.key,
                take: self.take,
                skip: self.skip.subtracting(other))
        } else if other.key == self.key {
            let newTake = Set(self.take.keys)
                .map({ value -> (Value, MFDD<Key, Value>) in
                    let successor = other.take[value].map { rhs in
                        self.take[value]!.subtracting(rhs)
                    } ?? self.take[value]!
                    return (value, successor)
                })

            result = self.factory.makeNode(
                key : self.key,
                take: Dictionary(uniqueKeysWithValues: newTake),
                skip: self.skip.subtracting(other.skip))
        } else if other.key < self.key {
            result = self.subtracting(other.skip)
        } else {
            fatalError()
        }

        self.factory.subtractionCache[cacheKey] = result
        return result
    }

    init(key: Key, take: [Value: MFDD], skip: MFDD, factory: MFDDFactory<Key, Value>) {
        self.key     = key
        self.take    = take
        self.skip    = skip
        self.factory = factory
        self.count   = self.take.values.reduce(0, { $0 + $1.count }) + self.skip.count
    }

    init(factory: MFDDFactory<Key, Value>, count: Int) {
        self.key     = nil
        self.take    = nil
        self.skip    = nil
        self.factory = factory
        self.count   = count
    }

    static func areEqual(_ lhs: MFDD, _ rhs: MFDD) -> Bool {
        return (lhs.key   == rhs.key)
            && (lhs.count == rhs.count)
            && (lhs.take  == rhs.take)
            && (lhs.skip  == rhs.skip)
    }

    private var skipMost: MFDD {
        var result = self
        while !result.isTerminal {
            result = result.skip
        }
        return result
    }

}

extension MFDD: Sequence {

    public func makeIterator() -> AnyIterator<[Key: Value]> {
        // Implementation note: The iteration process sees the DD as a tree, and explores all his
        // nodes with a in-order traversal. During this traversal, we store all the keys of the
        // "take" parents, so that we can produce an item whenever we reach the one terminal.

        guard !self.isZero else { return AnyIterator { nil } }

        var stack = [(node: self, index: self.take?.startIndex)]
        while let (node, index) = stack.last {
            guard !node.isOne else { break }
            let successor = index != node.take.endIndex
                ? node.take[index!].value
                : node.skip!
            assert(!successor.isZero)
            stack.append((successor, successor.take?.startIndex))
        }

        return AnyIterator {
            guard !stack.isEmpty else { return nil }

            let keysWithValues: [(Key, Value)] = stack.compactMap({ (node, index) in
                if node.isTerminal {
                    return nil
                } else if index != node.take.endIndex {
                    return (node.key, node.take[index!].key)
                } else {
                    return nil
                }
            })

            advance: while let (node, index) = stack.popLast() {
                if !node.isTerminal && (index != node.take.endIndex) {
                    stack.append((node, node.take.index(after: index!)))

                    while let (chilNode, childIndex) = stack.last {
                        guard !chilNode.isZero else {
                            stack.removeLast()
                            continue advance
                        }

                        guard !chilNode.isOne else { break advance }
                        let successor = childIndex != chilNode.take.endIndex
                            ? chilNode.take[childIndex!].value
                            : chilNode.skip!
                        stack.append((successor, successor.take?.startIndex))
                    }
                }
            }

            return Dictionary(uniqueKeysWithValues: keysWithValues)
        }
    }

}

extension MFDD: CustomStringConvertible {

    public var description: String {
        let contentDescription = self
            .map({ element in element.description })
            .joined(separator: ", ")
        return "[\(contentDescription)]"
    }

}
