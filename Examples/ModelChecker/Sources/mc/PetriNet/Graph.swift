/// A marking graph.
public struct MarkingGraph<PlaceType, TransitionType>
  where PlaceType: Place, TransitionType: Transition
{

  /// The root of the graph.
  public let root: Node<PlaceType, TransitionType>

  /// Creates a marking graph from the given root.
  ///
  /// - Parameter root: The root of the marking graph.
  public init(root: Node<PlaceType, TransitionType>) {
    self.root = root
  }

  /// Creates a marking graph from a Petri net and an initial marking.
  ///
  /// This constructor fails if the model provided is unbounded.
  ///
  /// - Parameters:
  ///   - petrinet: The model from for which the marking graph is created.
  ///   - initialMarking: The initial marking from which the marking graph is created.
  public init?(
    of petrinet: PetriNet<PlaceType, TransitionType>,
    from initialMarking: Marking<PlaceType, Int>)
  {
    // The root of the graph is the initial marking.
    root = Node<PlaceType, TransitionType>(marking: initialMarking)

    // Create arrays to keep track of the nodes that have been created, and the ones that have yet
    // to be traversed by the algorithm.
    var created = [root]
    var unprocessed = [root]

    while let node = unprocessed.popLast() {
      for transition in TransitionType.allCases {
        // Compute the current marking's successors for all fireable transitions.
        guard let nextMarking = petrinet.fire(transition: transition, from: node.marking)
          else { continue }

        // Check if this particular successor has already been created.
        if let successor = created.first(where : { other in other.marking == nextMarking }) {
          node.successors[transition] = successor
          continue
        }

        // Check that the model is bounded.
        guard created.contains(where: { n in n.marking >= nextMarking })
          else { return nil }

        // The successor hasn't been created yet, so add it to the list of unprocessed nodes.
        let successor = Node<PlaceType, TransitionType>(marking: nextMarking)
        created.append(successor)
        unprocessed.append(successor)
        node.successors[transition] = successor
      }
    }
  }

}

extension MarkingGraph: Sequence {

  public func makeIterator() -> AnyIterator<Node<PlaceType, TransitionType>> {
    var unprocessed = Set([root])
    var processed: Set<Node<PlaceType, TransitionType>> = []

    return AnyIterator {
      guard let node = unprocessed.popFirst()
        else { return nil }

      processed.insert(node)
      unprocessed.formUnion(Set(node.successors.values).subtracting(processed))
      assert(processed.intersection(unprocessed).isEmpty)
      return node
    }
  }

  /// The number of states in the graph.
  public var count: Int {
    return reduce(0) { result, _ in result + 1 }
  }

}

/// A node of a marking graph.
public class Node<PlaceType, TransitionType> where PlaceType: Place, TransitionType: Transition {

  /// The marking associated with this node.
  public let marking: Marking<PlaceType, Int>

  /// This node's successors.
  public fileprivate(set) var successors: [TransitionType: Node] = [:]

  fileprivate init(marking: Marking<PlaceType, Int>) {
    self.marking = marking
  }

}

extension Node: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  public static func == (lhs: Node, rhs: Node) -> Bool {
    return lhs === rhs
  }

}

extension PetriNet {

  /// Compute this model's marking graph, from the given initial marking.
  ///
  /// - Parameter marking: The model from for which the marking graph is created.
  /// - Returns: A marking graph is the model is bounded, or `nil` otherwise.
  public func markingGraph(from marking: Marking<PlaceType, Int>)
    -> MarkingGraph<PlaceType, TransitionType>?
  {
    return MarkingGraph(of: self, from: marking)
  }

}
