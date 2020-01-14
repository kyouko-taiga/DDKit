extension SFDD: Sequence {

  public func makeIterator() -> SFDDIterator<Key> {
    SFDDIterator(pointer: pointer, factory: factory)
  }

  /// Returns a random member of the family, using the given generator as a source for randomness.
  public func randomElement<T>(using generator: inout T) -> Set<Key>?
    where T: RandomNumberGenerator
  {
    guard !isEmpty
      else { return nil }

    var pointer = self.pointer
    var member: Set<Key> = []

    while pointer != factory.onePointer {
      if (pointer.pointee.skip != factory.zeroPointer) && Bool.random(using: &generator) {
        pointer = pointer.pointee.skip
      } else {
        member.insert(pointer.pointee.key)
        pointer = pointer.pointee.take
      }
    }

    return member
  }

  /// Returns a random member of the family.
  public func randomElement() -> Set<Key>? {
    var generator = SystemRandomNumberGenerator()
    return randomElement(using: &generator)
  }

}

public struct SFDDIterator<Key>: IteratorProtocol where Key: Comparable & Hashable {

  private var partialResult: [Key] = []

  private var stack: [SFDD<Key>.Pointer] = []

  private var pointer: SFDD<Key>.Pointer?

  private let factory: SFDDFactory<Key>

  fileprivate init(pointer: SFDD<Key>.Pointer?, factory: SFDDFactory<Key>) {
    self.pointer = pointer
    self.factory = factory
  }

  public mutating func next() -> Set<Key>? {
    guard pointer != nil
      else { return nil }

    while pointer != factory.zeroPointer {
      if pointer == factory.onePointer {
        let result = Set(partialResult)
        pointer = stack.popLast()
        if pointer != nil {
          partialResult = partialResult.filter({ $0 < pointer!.pointee.key })
          pointer = pointer!.pointee.skip
        }

        return result
      } else if pointer!.pointee.skip != factory.zeroPointer {
        stack.append(pointer!)
      }

      partialResult.append(pointer!.pointee.key)
      pointer = pointer!.pointee.take
    }

    return nil
  }

}
