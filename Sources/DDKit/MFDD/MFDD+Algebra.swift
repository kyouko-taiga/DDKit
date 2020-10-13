// MARK: Actual implementations

extension MFDDFactory {

  public func contains<S>(_ pointer: MFDD<Key, Value>.Pointer, _ member: S) -> Bool
    where S: Sequence, S.Element == (key: Key, value: Value)
  {
    var it = member.makeIterator()

    var currentPointer = pointer
    var element = it.next()

    while element != nil && !isTerminal(currentPointer) {
      if currentPointer.pointee.key < element!.key {
        currentPointer = currentPointer.pointee.skip
      } else if currentPointer.pointee.key == element!.key {
        guard let nextPointer = currentPointer.pointee.take[element!.value]
          else { return false }
        currentPointer = nextPointer
        element = it.next()
      } else {
        currentPointer = currentPointer.pointee.skip
      }
    }

    return element == nil && skipMost(currentPointer) == onePointer
  }

  /// Returns the union of two MFDDs.
  public func union(
    _ lhs: MFDD<Key, Value>.Pointer,
    _ rhs: MFDD<Key, Value>.Pointer
  ) -> MFDD<Key, Value>.Pointer
  {
    // Check for trivial cases.
    if lhs == zeroPointer || lhs == rhs {
      return rhs
    } else if rhs == zeroPointer {
      return lhs
    }

    // Query the cache.
    let cacheKey = lhs < rhs ? [lhs, rhs] : [rhs, lhs]
    if let pointer = cache.union[cacheKey] {
      return pointer
    }

    // Compute the union of `lhs` with `rhs`.
    let result: MFDD<Key, Value>.Pointer
    if lhs == onePointer {
      result = node(
        key: rhs.pointee.key,
        take: rhs.pointee.take,
        skip: union(lhs, rhs.pointee.skip))
    } else if rhs == onePointer {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: union(rhs, lhs.pointee.skip))
    } else if lhs.pointee.key < rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: union(lhs.pointee.skip, rhs))
    } else if lhs.pointee.key == rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take.merging(rhs.pointee.take, uniquingKeysWith: union),
        skip: union(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = node(
        key: rhs.pointee.key,
        take: rhs.pointee.take,
        skip: union(rhs.pointee.skip, lhs))
    }

    cache.union[cacheKey] = result
    return result
  }

  /// Returns the intersection of two MFDDs.
  public func intersection(
    _ lhs: MFDD<Key, Value>.Pointer,
    _ rhs: MFDD<Key, Value>.Pointer
  ) -> MFDD<Key, Value>.Pointer
  {
    // Check for trivial cases.
    if lhs == zeroPointer || lhs == rhs {
      return lhs
    } else if rhs == zeroPointer {
      return rhs
    }

    // Query the cache.
    let cacheKey = lhs < rhs ? [lhs, rhs] : [rhs, lhs]
    if let pointer = cache.intersection[cacheKey] {
      return pointer
    }

    // Compute the intersection of `lhs` with `rhs`.
    let result: MFDD<Key, Value>.Pointer
    if lhs == onePointer {
      result = skipMost(rhs)
    } else if rhs == onePointer {
      result = skipMost(lhs)
    } else if lhs.pointee.key < rhs.pointee.key {
      result = intersection(lhs.pointee.skip, rhs)
    } else if lhs.pointee.key == rhs.pointee.key {
      let take: [(key: Value, value: MFDD<Key, Value>.Pointer)] = lhs.pointee.take
        .compactMap({ (value: Value, child: MFDD<Key, Value>.Pointer) in
          rhs.pointee.take[value].map({ (value, intersection(child, $0)) })
        })

      result = node(
        key: lhs.pointee.key,
        take: Dictionary(uniqueKeysWithValues: take),
        skip: intersection(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = intersection(lhs, rhs.pointee.skip)
    }

    cache.intersection[cacheKey] = result
    return result
  }

  /// Returns the symmetric difference (a.k.a. disjunctive union) between two MFDDs.
  public func symmetricDifference(
    _ lhs: MFDD<Key, Value>.Pointer,
    _ rhs: MFDD<Key, Value>.Pointer
  ) -> MFDD<Key, Value>.Pointer
  {
    // Check for trivial cases.
    if lhs == zeroPointer {
      return rhs
    } else if rhs == zeroPointer {
      return lhs
    } else if lhs == rhs {
      return zeroPointer
    }

    // Query the cache.
    let cacheKey = lhs < rhs ? [lhs, rhs] : [rhs, lhs]
    if let pointer = cache.symmetricDifference[cacheKey] {
      return pointer
    }

    // Compute the symmetric difference between `lhs` and `rhs`.
    let result: MFDD<Key, Value>.Pointer
    if lhs == onePointer {
      result = node(
        key: rhs.pointee.key,
        take: rhs.pointee.take,
        skip: symmetricDifference(lhs, rhs.pointee.skip))
    } else if rhs == onePointer {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: symmetricDifference(lhs.pointee.skip, rhs))
    } else if lhs.pointee.key < rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: symmetricDifference(lhs.pointee.skip, rhs))
    } else if lhs.pointee.key == rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take.merging(rhs.pointee.take, uniquingKeysWith: symmetricDifference),
        skip: symmetricDifference(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = node(
        key: rhs.pointee.key,
        take: rhs.pointee.take,
        skip: symmetricDifference(lhs, rhs.pointee.skip))
    }

    cache.symmetricDifference[cacheKey] = result
    return result
  }

  /// Returns `lhs` subtracting `rhs`.
  public func subtraction(
    _ lhs: MFDD<Key, Value>.Pointer,
    _ rhs: MFDD<Key, Value>.Pointer
  ) -> MFDD<Key, Value>.Pointer
  {
    // Check for trivial cases.
    if lhs == zeroPointer || rhs == zeroPointer {
      return lhs
    } else if lhs == rhs {
      return zeroPointer
    }

    // Query the cache.
    let cacheKey = lhs < rhs ? [lhs, rhs] : [rhs, lhs]
    if let pointer = cache.subtraction[cacheKey] {
      return pointer
    }

    // Compute `lhs` subtracting `rhs`.
    let result: MFDD<Key, Value>.Pointer
    if lhs == onePointer {
      result = skipMost(rhs) == zeroPointer ? lhs : zeroPointer
    } else if rhs == onePointer {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: subtraction(lhs.pointee.skip, rhs))
    } else if lhs.pointee.key < rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: lhs.pointee.take,
        skip: subtraction(lhs.pointee.skip, rhs))
    } else if lhs.pointee.key == rhs.pointee.key {
      let take: [(key: Value, value: MFDD<Key, Value>.Pointer)] = lhs.pointee.take
        .compactMap({ (value, child) in
          rhs.pointee.take[value] == nil ? (value, child) : rhs.pointee.take[value].map({ (value, subtraction(child, $0)) })
        })
      
      result = node(
        key: lhs.pointee.key,
        take: Dictionary(uniqueKeysWithValues: take),
        skip: subtraction(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = subtraction(lhs, rhs.pointee.skip)
    }
    
    cache.subtraction[cacheKey] = result
    return result
  }

  /// Returns the terminal obtained by following the skip branch of the given MFDD.
  public func skipMost(_ pointer: MFDD<Key, Value>.Pointer) -> MFDD<Key, Value>.Pointer {
    var result = pointer
    while result != zeroPointer && result != onePointer {
      result = result.pointee.skip
    }
    return result
  }

}
