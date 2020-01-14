extension MFDD: Sequence {

  public func makeIterator() -> MFDDIterator<Key, Value> {
    MFDDIterator(pointer: pointer, factory: factory)
  }

  /// Returns a random member of the family, using the given generator as a source for randomness.
  public func randomElement<T>(using generator: inout T) -> [Key: Value]?
    where T: RandomNumberGenerator
  {
    guard !isEmpty
      else { return nil }

    var pointer = self.pointer
    var member: [Key: Value] = [:]

    while pointer != factory.onePointer {
      let key = pointer.pointee.key
      if pointer.pointee.skip != factory.zeroPointer {
        let iterator = MFDDChildrenIterator(pointer: pointer, factory: factory)
        (member[key], pointer) = Array(iterator).randomElement(using: &generator)!
      } else {
        (member[key], pointer) = pointer.pointee.take.randomElement(using: &generator)!
      }
    }

    return member
  }

  /// Returns a random member of the family.
  public func randomElement() -> [Key: Value]? {
    var generator = SystemRandomNumberGenerator()
    return randomElement(using: &generator)
  }

}


public struct MFDDIterator<Key, Value>: IteratorProtocol
  where Key: Comparable & Hashable, Value: Hashable
{

  private var partialResult: [Key: Value] = [:]

  private var stack: [MFDDChildrenIterator<Key, Value>] = []

  private let factory: MFDDFactory<Key, Value>

  fileprivate init(pointer: MFDD<Key, Value>.Pointer, factory: MFDDFactory<Key, Value>) {
    self.stack = [MFDDChildrenIterator(pointer: pointer, factory: factory)]
    self.factory = factory
  }

  public mutating func next() -> [Key: Value]? {
    while !stack.isEmpty {
      if let (value, child) = stack[stack.count - 1].next() {
        partialResult[stack[stack.count - 1].pointer.pointee.key] = value
        stack.append(MFDDChildrenIterator(pointer: child, factory: factory))
      } else {
        defer {
          stack.removeLast()
          if let last = stack.last, !factory.isTerminal(last.pointer) {
            partialResult = partialResult.filter({ $0.key < last.pointer.pointee.key })
          }
        }

        if stack.last!.pointer == factory.onePointer {
          return partialResult
        }
      }
    }

    return nil
  }

}

fileprivate struct MFDDChildrenIterator<Key, Value>: IteratorProtocol, Sequence
  where Key: Comparable & Hashable, Value: Hashable
{

  enum Cursor {
    case take(Dictionary<Value, MFDD<Key, Value>.Pointer>.Index)
    case skip
    case end
  }

  private var cursor: Cursor

  let pointer: MFDD<Key, Value>.Pointer

  let factory: MFDDFactory<Key, Value>

  init(pointer: MFDD<Key, Value>.Pointer, factory: MFDDFactory<Key, Value>) {
    self.pointer = pointer
    self.factory = factory
    self.cursor = factory.isTerminal(pointer)
      ? .end
      : .take(pointer.pointee.take.startIndex)
  }

  mutating func next() -> (value: Value?, child: MFDD<Key, Value>.Pointer)? {
    switch cursor {
    case .take(let takeIndex):
      let successorIndex = pointer.pointee.take.index(after: takeIndex)
      cursor = successorIndex < pointer.pointee.take.endIndex
        ? .take(successorIndex)
        : .skip
      return pointer.pointee.take[takeIndex] as (Value?, MFDD<Key, Value>.Pointer)

    case .skip:
      cursor = .end
      return (nil, pointer.pointee.skip)

    case .end:
      return nil
    }
  }

}
