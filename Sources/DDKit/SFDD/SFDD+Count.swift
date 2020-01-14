extension SFDD {

  private struct MemberCounter {

    var cache: [Pointer: Int]

    init(factory: SFDDFactory<Key>) {
      cache = [factory.zeroPointer: 0, factory.onePointer: 1]
    }

    mutating func visit(_ pointer: Pointer) -> Int {
      if let count = cache[pointer] {
        return count
      }

      let count = visit(pointer.pointee.take) + visit(pointer.pointee.skip)
      cache[pointer] = count
      return count
    }

  }

  /// The number of members in the family.
  public var count: Int {
    var counter = MemberCounter(factory: factory)
    return counter.visit(pointer)
  }

}
