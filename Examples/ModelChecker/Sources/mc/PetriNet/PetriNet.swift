/// A Petri net.
///
/// `PetriNet` is a generic type, accepting two types representing the set of places and the set
/// of transitions that structurally compose the model. Both should conform to `CaseIterable`,
/// which guarantees that the set of places (resp. transitions) is bounded, and known statically.
/// The following example illustrates how to declare the places and transition of a simple Petri
/// net representing an on/off switch:
///
///     enum P: Place {
///       typealias Content = Int
///       case on, off
///     }
///
///     enum T: Transition {
///       case switchOn, switchOff
///     }
///
/// Petri net instances are created by providing the list of the preconditions and postconditions
/// that compose them. These should be provided in the form of arc descriptions (i.e. instances of
/// `ArcDescription`) and fed directly to the Petri net's initializer. The following example shows
/// how to create an instance of the on/off switch:
///
///
///     let model = PetriNet<P, T>(
///       .pre(from: .on, to: .switchOff),
///       .post(from: .switchOff, to: .off),
///       .pre(from: .off, to: .switchOn),
///       .post(from: .switchOn, to: .on),
///     )
///
/// Petri net instances only represent the structual part of the corresponding model, meaning that
/// markings should be stored externally. They can however be used to compute the marking resulting
/// from the firing of a particular transition, using the method `fire(transition:from:)`. The
/// following example illustrates this method's usage:
///
///     if let marking = model.fire(.switchOn, from: [.on: 0, .off: 1]) {
///       print(marking)
///     }
///     // Prints "[.on: 1, .off: 0]"
///
public struct PetriNet<PlaceType, TransitionType>
  where PlaceType: Place, TransitionType: Transition
{

  public typealias ArcLabel = Int

  /// The description of an arc.
  public struct ArcDescription {

    /// The place to which the arc is connected.
    fileprivate let place: PlaceType

    /// The transition to which the arc is connected.
    fileprivate let transition: TransitionType

    /// The arc's label.
    fileprivate let label: Int

    /// The arc's direction.
    fileprivate let isPre: Bool

    fileprivate init(place: PlaceType, transition: TransitionType, label: Int, isPre: Bool) {
      self.place = place
      self.transition = transition
      self.label = label
      self.isPre = isPre
    }

    /// Creates the description of a precondition arc.
    ///
    /// - Parameters:
    ///   - place: The place from which the arc comes.
    ///   - transition: The transition to which the arc goes.
    ///   - label: The arc's label.
    public static func pre(
      from place: PlaceType,
      to transition: TransitionType,
      labeled label: Int = 1)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: true)
    }

    /// Creates the description of a postcondition arc.
    ///
    /// - Parameters:
    ///   - transition: The transition from which the arc comes.
    ///   - place: The place to which the arc goes.
    ///   - label: The arc's label.
    public static func post(
      from transition: TransitionType,
      to place: PlaceType,
      labeled label: Int = 1)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: false)
    }

  }

  /// The partial description of an arc going into or out of a transition.
  public struct PartialArcDescription {

    /// The place to which the arc is connected.
    fileprivate let place: PlaceType

    /// The arc's label.
    fileprivate let label: Int

    /// The arc's direction.
    fileprivate let isPre: Bool

    fileprivate init(place: PlaceType, label: Int, isPre: Bool) {
      self.place = place
      self.label = label
      self.isPre = isPre
    }

    /// Completes this partial description with the given transition.
    ///
    /// - Parameters:
    ///   - transition: The transition that is missing from this description.
    /// - Returns: A complete arc description.
    fileprivate func complete(withTransition transition: TransitionType) -> ArcDescription {
      return ArcDescription(place: place, transition: transition, label: label, isPre: isPre)
    }

    /// Creates the description of a precondition arc.
    ///
    /// - Parameters:
    ///   - place: The place from which the arc comes.
    ///   - label: The arc's label.
    public static func pre(
      from place: PlaceType,
      labeled label: Int = 1)
      -> PartialArcDescription
    {
      return PartialArcDescription(place: place, label: label, isPre: true)
    }

    /// Creates the description of a postcondition arc.
    ///
    /// - Parameters:
    ///   - place: The place to which the arc goes.
    ///   - label: The arc's label.
    public static func post(
      to place: PlaceType,
      labeled label: Int = 1)
      -> PartialArcDescription
    {
      return PartialArcDescription(place: place, label: label, isPre: false)
    }

  }


  /// The description of a transition.
  public struct TransitionDescription {

    /// The transition being described.
    fileprivate let transition: TransitionType

    /// The transition's arcs.
    fileprivate let arcs: [PartialArcDescription]

    private init(transition: TransitionType, _ arcs: [PartialArcDescription]) {
      self.transition = transition
      self.arcs = arcs
    }

    /// Creates the description of a transition.
    ///
    /// - Parameters:
    ///   - transition: The transition to describe.
    ///   - arcs: A sequence containing the descriptions of the transition's arcs.
    public static func transition(_ transition: TransitionType, arcs: PartialArcDescription...)
      -> TransitionDescription
    {
      return TransitionDescription(transition: transition, arcs)
    }

  }

  /// This net's input matrix.
  public let input: [TransitionType: [PlaceType: ArcLabel]]

  /// This net's output matrix.
  public let output: [TransitionType: [PlaceType: ArcLabel]]

  /// Initializes a Petri net with a sequence describing its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A sequence containing the descriptions of the Petri net's arcs.
  public init<Arcs>(_ arcs: Arcs) where Arcs: Sequence, Arcs.Element == ArcDescription {
    var pre: [TransitionType: [PlaceType: ArcLabel]] = [:]
    var post: [TransitionType: [PlaceType: ArcLabel]] = [:]

    for arc in arcs {
      if arc.isPre {
        PetriNet.add(arc: arc, to: &pre)
      } else {
        PetriNet.add(arc: arc, to: &post)
      }
    }

    self.input = pre
    self.output = post
  }

  /// Initializes a Petri net with descriptions of its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A variadic argument representing the descriptions of the Petri net's arcs.
  public init(_ arcs: ArcDescription...) {
    self.init(arcs)
  }

  /// Initializes a Petri net with descriptions of its transitions.
  ///
  /// - Parameters:
  ///   - transitions: A variadic argument representing the descriptions of the Petri net's
  ///     transitions.
  public init(_ transitions: TransitionDescription...) {
    let arcs = transitions.map { description in
      description.arcs.map { $0.complete(withTransition: description.transition) }
    }
    self.init(arcs.joined())
  }

  /// Computes the marking resulting from the firing of the given transition, from the given
  /// marking, assuming the former is fireable.
  ///
  /// - Parameters:
  ///   - transition: The transition to fire.
  ///   - marking: The marking from which the given transition should be fired.
  /// - Returns:
  ///   The marking that results from the firing of the given transition if it is fireable, or
  ///   `nil` otherwise.
  public func fire(transition: TransitionType, from marking: Marking<PlaceType, Int>)
    -> Marking<PlaceType, Int>?
  {
    var newMarking = marking

    let pre = input[transition]
    let post = output[transition]

    for place in PlaceType.allCases {
      if let n = pre?[place] {
        guard marking[place] >= n
          else { return nil }
        newMarking[place] -= n
      }

      if let n = post?[place] {
        newMarking[place] += n
      }
    }

    return newMarking
  }

  /// Internal helper to process preconditions and postconditions.
  private static func add(
    arc: ArcDescription,
    to matrix: inout [TransitionType: [PlaceType: ArcLabel]])
  {
    if var column = matrix[arc.transition] {
      precondition(column[arc.place] == nil, "duplicate arc declaration")
      column[arc.place] = arc.label
      matrix[arc.transition] = column
    } else {
      matrix[arc.transition] = [arc.place: arc.label]
    }
  }

}

/// A place in a Petri net.
public protocol Place: CaseIterable, Hashable {

}

/// A transition in a Petri net.
public protocol Transition: CaseIterable, Hashable {

}
