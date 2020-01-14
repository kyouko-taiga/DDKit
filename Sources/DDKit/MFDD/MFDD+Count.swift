extension MFDD {

  private struct MemberCounter {

    var cache: [Pointer: Int]

    init(factory: MFDDFactory<Key, Value>) {
      cache = [factory.zeroPointer: 0, factory.onePointer: 1]
    }

    mutating func visit(_ pointer: Pointer) -> Int {
      if let count = cache[pointer] {
        return count
      }

      var count = visit(pointer.pointee.skip)
      for (_, child) in pointer.pointee.take {
        count = count + visit(child)
      }
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
