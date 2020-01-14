extension SFDD {

  /// Returns a new family with the members of this family and of the given other families.
  public func union<S>(others: S) -> SFDD where S: Sequence, S.Element == SFDD {
    SFDD(pointer: factory.union(of: [pointer] + others.map({ $0.pointer })), factory: factory)
  }

  /// Returns a new family with the members that are common to this family and to the given other
  /// families.
  public func intersection<S>(others: S) -> SFDD where S: Sequence, S.Element == SFDD {
    SFDD(
      pointer: factory.intersection(of: [pointer] + others.map({ $0.pointer })),
      factory: factory)
  }

}

// MARK: Actual implementations

extension SFDDFactory {

  public func contains<S>(_ pointer: SFDD<Key>.Pointer, _ member: S) -> Bool
    where S: Sequence, S.Element == Key
  {
    var it = member.makeIterator()

    var currentPointer = pointer
    var key = it.next()

    while key != nil && !isTerminal(currentPointer) {
      if currentPointer.pointee.key < key! {
        currentPointer = currentPointer.pointee.skip
      } else if currentPointer.pointee.key == key! {
        currentPointer = currentPointer.pointee.take
        key = it.next()
      } else {
        currentPointer = currentPointer.pointee.skip
      }
    }

    return key == nil && skipMost(currentPointer) == onePointer
  }

  /// Returns the union of two SFDDs.
  public func union(_ lhs: SFDD<Key>.Pointer, _ rhs: SFDD<Key>.Pointer) -> SFDD<Key>.Pointer {
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
    let result: SFDD<Key>.Pointer
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
        take: union(lhs.pointee.take, rhs.pointee.take),
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

  /// Returns the union of multiple SFDDs.
  public func union<S>(of families: S) -> SFDD<Key>.Pointer
    where S: Sequence, S.Element == SFDD<Key>.Pointer
  {
    // Extract the non-zero operands and check for trivial cases.
    let operands = Set(families.filter({ pointer in pointer != zeroPointer }))
    switch operands.count {
    case 0:
      return zeroPointer
    case 1:
      return operands.first!
    case 2:
      let startIndex = operands.startIndex
      return union(operands[startIndex], operands[operands.index(after: startIndex)])
    default:
      break
    }

    // Query the cache.
    let cacheKey = operands.sorted()
    if let pointer = cache.union[cacheKey] {
      return pointer
    }

    // Sort the operands by key, from the lowest to the greatest.
    let sorted = operands.sorted(by: { a, b in
      b == onePointer || a != onePointer && (a.pointee.key < b.pointee.key)
    })

    // We can assume that we there are at least three operands from the above switch statement.
    // Consequently, as the one terminal is placed after any other node in the sorted list, the
    // first operand is necessarily a non-terminal node.
    assert(sorted[0] != onePointer)

    // Separate the DDs with the lowest key from the others.
    let key = sorted[0].pointee.key
    let prefix = sorted.prefix(while: { $0 != onePointer && $0.pointee.key == key })
    let suffix = sorted.dropFirst(prefix.count)

    // The union is given by the node such that:
    // - its key is the lowest key of all operands;
    // - its take branch is the union of the take branches of all nodes with the same key;
    // - its skip branch is the union of the skip branches of all nodes with the same key, as well
    //   as the other operands.
    let take = prefix.count > 1
      ? union(of: prefix.map({ $0.pointee.take }))
      : prefix.first!.pointee.take
    let skip = union(of: prefix.map({ $0.pointee.skip }) + suffix)
    let result = node(key: key, take: take, skip: skip)

    cache.union[cacheKey] = result
    return result
  }

  /// Returns the intersection of two SFDDs.
  public func intersection(
    _ lhs: SFDD<Key>.Pointer,
    _ rhs: SFDD<Key>.Pointer
  ) -> SFDD<Key>.Pointer
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
    let result: SFDD<Key>.Pointer
    if lhs == onePointer {
      result = skipMost(rhs)
    } else if rhs == onePointer {
      result = skipMost(lhs)
    } else if lhs.pointee.key < rhs.pointee.key {
      result = intersection(lhs.pointee.skip, rhs)
    } else if lhs.pointee.key == rhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: intersection(lhs.pointee.take, rhs.pointee.take),
        skip: intersection(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = intersection(lhs, rhs.pointee.skip)
    }

    cache.intersection[cacheKey] = result
    return result
  }

  /// Returns the intersection of multiple SFDDs.
  public func intersection<S>(of families: S) -> SFDD<Key>.Pointer
    where S: Sequence, S.Element == SFDD<Key>.Pointer
  {
    // Check for trivial cases.
    let operands = Set(families)
    guard !operands.contains(zeroPointer)
      else { return zeroPointer }

    switch operands.count {
    case 0:
      return zeroPointer
    case 1:
      return operands.first!
    case 2:
      let startIndex = operands.startIndex
      return intersection(operands[startIndex], operands[operands.index(after: startIndex)])
    default:
      break
    }

    // Query the cache.
    let cacheKey = operands.sorted()
    if let pointer = cache.intersection[cacheKey] {
      return pointer
    }

    // Sort the operands by key, from the greatest to the lowest.
    let sorted = operands.sorted(by: { a, b in
      !(b == onePointer || a != onePointer && (a.pointee.key < b.pointee.key))
    })

    if sorted[0] == onePointer {
      // If the operands contain the one terminal, return the one if all operands' skip-most
      // terminal is also one, otherwise return zero.
      let result = sorted[1...].map(skipMost).contains(zeroPointer)
        ? zeroPointer
        : onePointer
      cache.intersection[cacheKey] = result
      return result
    }

    // Separate the DDs with the greatest key from the others.
    let key = sorted[0].pointee.key
    let prefix = sorted.prefix(while: { $0.pointee.key == key })
    let suffix = sorted.dropFirst(prefix.count)
      .map({ (pointer: SFDD<Key>.Pointer) -> SFDD<Key>.Pointer in
        // Ignore all DDs whose key is lowest than the greatest key.
        var result = pointer
        while result != zeroPointer && result != onePointer {
          guard result.pointee.key < key
            else { return result }
          result = result.pointee.skip
        }
        return result
      })

    guard !suffix.contains(zeroPointer)
      else { return zeroPointer }

    // The intersection is given by the node such that:
    // - its key is the greatest key of all operands;
    // - its take branch is the intersection of the take branches of all nodes with the same key;
    // - its skip branch is the intersection of the skip branches of all nodes with the same key,
    //   as well as the other operands.
    let take = prefix.count > 1
      ? intersection(of: prefix.map({ $0.pointee.take }))
      : prefix.first!.pointee.take
    let skip = intersection(of: prefix.map({ $0.pointee.skip }) + suffix)
    let result = node(key: key, take: take, skip: skip)

    cache.intersection[cacheKey] = result
    return result
  }

  /// Returns the symmetric difference (a.k.a. disjunctive union) between two SFDDs.
  public func symmetricDifference(
    _ lhs: SFDD<Key>.Pointer,
    _ rhs: SFDD<Key>.Pointer
  ) -> SFDD<Key>.Pointer
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
    let result: SFDD<Key>.Pointer
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
    } else if lhs.pointee.key == lhs.pointee.key {
      result = node(
        key: lhs.pointee.key,
        take: symmetricDifference(lhs.pointee.take, rhs.pointee.take),
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
    _ lhs: SFDD<Key>.Pointer,
    _ rhs: SFDD<Key>.Pointer
  ) -> SFDD<Key>.Pointer
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
    let result: SFDD<Key>.Pointer
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
      result = node(
        key: lhs.pointee.key,
        take: subtraction(lhs.pointee.take, rhs.pointee.take),
        skip: subtraction(lhs.pointee.skip, rhs.pointee.skip))
    } else {
      result = subtraction(lhs, rhs.pointee.skip)
    }

    cache.subtraction[cacheKey] = result
    return result
  }

  /// Returns the terminal obtained by following the skip branch of the given SFDD.
  public func skipMost(_ pointer: SFDD<Key>.Pointer) -> SFDD<Key>.Pointer {
    var result = pointer
    while result != zeroPointer && result != onePointer {
      result = result.pointee.skip
    }
    return result
  }

}
