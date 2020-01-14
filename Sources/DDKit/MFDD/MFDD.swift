/// A map family decision diagram.
///
/// Map Family Decision Diagrams (MFDDs) are structures capable of representing large families of
/// maps (a.k.a. dictionaries), and performing various operations on them efficiently. They take
/// advantage of the similarities between family members to compact their representation in a
/// graph-like structure that can be manipulated with morphisms.
///
/// Creating MFDDs
/// --------------
///
/// MFDD nodes must be unique so that the results of operations applyed on them can be cached. This
/// means that MFDDs must be created by the means of a factory (i.e. `MFDDFactory`).
///
///     let factory = MFDDFactory<String, Int>()
///     let family = factory.encode(family: [["a": 1, "b": 2], ["a": 3]])
///     print(family)
///     // Prints "[["a": 1, "b": 2], ["a": 3]]"
///
/// Note that performing operations of SFDDs that were created by different factories may corrupt
/// operation caches, invalidating results and potentially triggering memory eerors.
public struct MFDD<Key, Value>: DecisionDiagram where Key: Comparable & Hashable, Value: Hashable {

  public typealias Pointer = UnsafeMutablePointer<Node>
  public typealias Factory = MFDDFactory<Key, Value>

  /// A node in the graph representation of a MFDD.
  public struct Node: Hashable {

    var inUse: Bool

    /// The key associated with this node.
    public var key: Key

    /// The dictionary mapping key's assignments to this node's take branches.
    public var take: [Value: Pointer]

    /// A pointer to this node's skip branch.
    public var skip: Pointer

    var precomputedHash: Int

    public func hash(into hasher: inout Hasher) {
      hasher.combine(precomputedHash)
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
      lhs.key == rhs.key && lhs.take == rhs.take && lhs.skip == rhs.skip
    }

  }

  /// The pointer to the actual underlying node.
  ///
  /// This property should be used for low-level operations and morphisms only.
  ///
  /// - Warning: The node pointed by this property corresponds to the actual representation of the
  ///   decision diagram, whose memory is controlled by the factory. For the sake of regularity,
  ///   terminal nodes (i.e. `zero` and `one`) are also represented as regular nodes, removing the
  ///   need for dynamic dispatch. However, dereferencing the key, take or skip property of a
  ///   terminal node will likely result in an unrecoverable memory error. Therefore, one should
  ///   always check that a pointer does not point to a terminal before dereferencing its pointee.
  public let pointer: Pointer

  /// The factory that created this family.
  public unowned let factory: MFDDFactory<Key, Value>

  /// Initializes a MFDD from a node pointer and the factory that created it.
  public init(pointer: Pointer, factory: MFDDFactory<Key, Value>) {
    self.pointer = pointer
    self.factory = factory
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(pointer)
  }

  public static func == (lhs: MFDD, rhs: MFDD) -> Bool {
    return lhs.pointer == rhs.pointer
  }

}
