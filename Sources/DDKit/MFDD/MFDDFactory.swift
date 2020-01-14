/// A MFDD factory.
///
/// For the sake of performance, all decision diagram nodes should be unique so that an operations
/// on them can be cached. This factory guarantees such a uniqueness by keeping track of all
/// created nodes in a uniqueness table. When the method `node(key:take:skip:)` is called, this
/// table is queried to make sure there is not any existing node with the same parameters.
///
/// The factory also implements low-level family operations, such as the union, intersection,
/// symmetric difference (a.k.a. disjoint union) and subtraction.
///
/// In an effort to alleviate the cost of memory allocation, the uniqueness table is implemented as
/// a memory arena which gets allocated in large chunks of memory, called _buckets_. A bucket is
/// merely an array of nodes which is used as a hash table, using open addressing with quadratic
/// probing to handle hash collisions. When the load factor of a bucket is too high, an additional
/// bucket of the same size is created. Since this does not trigger any resizing, the addresses of
/// the slots in use are not invalidated.
public final class MFDDFactory<Key, Value>: DecisionDiagramFactory
  where Key: Comparable & Hashable, Value: Hashable
{

  public typealias DD = MFDD<Key, Value>

  /// A factory's cache for the results of family operations.
  struct Cache {

    var union: [[MFDD<Key, Value>.Pointer]: MFDD<Key, Value>.Pointer] = [:]

    var intersection: [[MFDD<Key, Value>.Pointer]: MFDD<Key, Value>.Pointer] = [:]

    var symmetricDifference: [[MFDD<Key, Value>.Pointer]: MFDD<Key, Value>.Pointer] = [:]

    var subtraction: [[MFDD<Key, Value>.Pointer]: MFDD<Key, Value>.Pointer] = [:]

  }

  /// A pointer to this factory's zero terminal.
  let zeroPointer: MFDD<Key, Value>.Pointer

  /// A pointer to this factory's one terminal.
  let onePointer: MFDD<Key, Value>.Pointer

  /// This factory's node buckets.
  private var buckets: [MFDD<Key, Value>.Pointer]

  /// The capacity of a single node bucket.
  private let bucketCapacity: Int

  /// This factory's cache for the results of family operations.
  var cache = Cache()

  /// The zero terminal.
  public var zero: MFDD<Key, Value> {
    MFDD(pointer: zeroPointer, factory: self)
  }

  /// The one terminal.
  public var one: MFDD<Key, Value> {
    MFDD(pointer: onePointer, factory: self)
  }

  /// A Boolean value indicating whether the given pointer points to a terminal node.
  public func isTerminal(_ pointer: MFDD<Key, Value>.Pointer) -> Bool {
    pointer == zeroPointer || pointer == onePointer
  }

  public func isEmpty(_ pointer: MFDD<Key, Value>.Pointer) -> Bool {
    return pointer == zeroPointer
  }

  /// The number of nodes created by the factory.
  public var createdCount: Int {
    var count = 0
    for bucket in buckets {
      for i in 0 ..< bucketCapacity where (bucket + i).pointee.inUse {
        count += 1
      }
    }
    return count
  }

  /// The associated morphism factory.
  public lazy var morphisms: MFDDMorphismFactory<Key, Value> = { [unowned self] in
    MFDDMorphismFactory(nodeFactory: self)
  }()

  /// Creates a new MFDD factory.
  ///
  /// - Parameter bucketCapacity: The number of slots to allocate for each bucket.
  public init(bucketCapacity: Int = 1024) {
    precondition(bucketCapacity > 0)
    self.bucketCapacity = bucketCapacity

    // Allocate the terminals.
    zeroPointer = MFDD<Key, Value>.Pointer.allocate(capacity: 2)
    onePointer = zeroPointer + 1
    for i in 0 ... 1 {
      let terminal = zeroPointer + i
      terminal.pointee.inUse = true
      terminal.pointee.precomputedHash = i
    }

    // Allocate the first bucket.
    buckets = [MFDD<Key, Value>.Pointer.allocate(capacity: bucketCapacity)]
    for i in 0 ..< bucketCapacity {
      (buckets[0] + i).pointee.inUse = false
    }
  }

  deinit {
    zeroPointer.deallocate()
    for i in 0 ..< buckets.count {
      buckets[i].deallocate()
    }
  }

  public func encode<S>(family: S) -> MFDD<Key, Value>
    where S: Sequence, S.Element: Sequence, S.Element.Element == (key: Key, value: Value)
  {
    let pointer = family.reduce(zeroPointer) { result, member in
      var ptr = onePointer
      for (key, value) in member.sorted(by: { a, b in a.key > b.key }) {
        ptr = node(key: key, take: [value: ptr], skip: zeroPointer)
      }
      return union(result, ptr)
    }
    return MFDD(pointer: pointer, factory: self)
  }

  /// Creates a new MFDD node.
  ///
  /// - Parameters:
  ///   - key: The node's key.
  ///   - take: A dictionary mapping values onto MFDDs representing suffixes for each assignment.
  ///   - skip: The MFDD representing the suffix if the key is dropped.
  ///
  /// - Returns: A MFDD node corresponding to the given parameters.
  public func node(
    key: Key,
    take: [Value: MFDD<Key, Value>.Pointer],
    skip: MFDD<Key, Value>.Pointer
  ) -> MFDD<Key, Value>.Pointer
  {
    let filteredTake = take.filter({ _, value in value != zeroPointer })
    guard !filteredTake.isEmpty
      else { return skip }

    assert(
      filteredTake.values.allSatisfy({ isTerminal($0) || key < $0.pointee.key }),
      "Invalid variable ordering: take branches should have a greater key.")
    assert(
      isTerminal(skip) || key < skip.pointee.key,
      "Invalid variable ordering: the skip branch should have a greater key.")

    // Search if there already exists a node with the given parameters.
    var hasher = Hasher()
    hasher.combine(key)
    hasher.combine(filteredTake)
    hasher.combine(skip)
    let hash = hasher.finalize()

    let remainder = hash % bucketCapacity
    let index = remainder >= 0 ? remainder : remainder + bucketCapacity
    for bucket in buckets {
      for i in 0 ..< 8 {
        // Compute the slot offset with quadratic function.
        let offset = index + Int((0.5 * Double(i)) + (0.5 * Double(i) * Double(i)))
        let pointer = offset < bucketCapacity
          ? bucket + offset
          : bucket + (offset % bucketCapacity)

        guard pointer.pointee.inUse else {
          // The current slot is not in use. This means that there isn't any node satisfying the
          // given parameters, and that we may use the slot to store a new one.
          pointer.initialize(to: MFDD.Node(
            inUse: true,
            key: key,
            take: filteredTake,
            skip: skip,
            precomputedHash: hash))
          return pointer
        }

        let node = pointer.pointee
        if node.precomputedHash == hash
          && node.key == key
          && node.take == filteredTake
          && node.skip == skip
        {
          // The current slot satisfies to the given parameters, so we return a pointer thereto.
          return pointer
        }
      }
    }

    // Since we got too many cache misses in all allocated buckets, we'll allocate a new one.
    buckets.append(MFDD<Key, Value>.Pointer.allocate(capacity: bucketCapacity))
    let base = buckets[buckets.count - 1]
    for i in 0 ..< bucketCapacity {
      (base + i).pointee.inUse = false
    }

    // Use a slot in the freshly allocated bucket.
    let pointer = base + index
    pointer.initialize(to: MFDD.Node(
      inUse: true,
      key: key,
      take: filteredTake,
      skip: skip,
      precomputedHash: hash))
    return pointer
  }

}
