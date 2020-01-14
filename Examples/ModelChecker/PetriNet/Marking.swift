/// A marking of a Petri net.
///
/// A marking is a mapping that associates the places of a Petri net to the tokens they contain.
///
/// An algebra is defined over markings if the type used to represent the tokens associated with
/// each place (i.e. `PlaceType`) allows it. More specifically, markings are comparable if tokens
/// are too, and even conform to `AdditiveArithmetic` if tokens do to.
///
/// The following example illustrates how to perform arithmetic operations of markings:
///
///     let m0: Marking<P> = [.p0: 1, .p1: 2]
///     let m1: Marking<P> = [.p0: 0, .p1: 1]
///     print(m0 + m1)
///     // Prints "[.p0: 1, .p1: 3]"
///
public struct Marking<PlaceType, PlaceContent> where PlaceType: Place {

  /// The total map that backs this marking.
  fileprivate var storage: TotalMap<PlaceType, PlaceContent>

  /// Initializes a marking with a total map.
  ///
  /// - Parameters:
  ///   - mapping: A total map representing this marking.
  public init(_ mapping: TotalMap<PlaceType, PlaceContent>) {
    self.storage = mapping
  }

  /// Initializes a marking with a dictionary.
  ///
  /// - Parameters:
  ///   - mapping: A dictionary representing this marking.
  ///
  /// The following example illustrates the use of this initializer:
  ///
  ///     let marking = Marking([.p0: 42, .p1: 1337])
  ///
  /// - Warning:
  ///   The given dictionary must be defined for all places, otherwise an error will be triggered
  ///   at runtime.
  public init(_ mapping: [PlaceType: PlaceContent]) {
    self.storage = TotalMap(mapping)
  }

  /// Initializes a marking with a function.
  ///
  /// - Parameters:
  ///   - mapping: A function mapping places to the tokens they contain.
  ///
  /// The following example illustrates the use of this initializer:
  ///
  ///     let marking = Marking { place in
  ///       switch place {
  ///       case .p0: return 42
  ///       case .p1: return 1337
  ///       }
  ///     }
  ///
  public init(_ mapping: (PlaceType) throws -> PlaceContent) rethrows {
    self.storage = try TotalMap(mapping)
  }

  /// Accesses the tokens associated with the given place for reading and writing.
  public subscript(place: PlaceType) -> PlaceContent {
    get { return storage[place] }
    set { storage[place] = newValue }
  }

  /// A collection containing just the places of the marking.
  public var places: PlaceType.AllCases {
    return PlaceType.allCases
  }

}

extension Marking: ExpressibleByDictionaryLiteral {

  public init(dictionaryLiteral elements: (PlaceType, PlaceContent)...) {
    let mapping = Dictionary(uniqueKeysWithValues: elements)
    self.storage = TotalMap(mapping)
  }

}

extension Marking: Equatable where PlaceContent: Equatable {

}

extension Marking: Hashable where PlaceContent: Hashable {

}

extension Marking: Comparable where PlaceContent: Comparable {

  public static func < (lhs: Marking, rhs: Marking) -> Bool {
    var smaller = false
    for place in PlaceType.allCases {
      if lhs[place] > rhs[place] {
        return false
      } else if lhs[place] < rhs[place] {
        smaller = true
      }
    }
    return smaller
  }

}

extension Marking: AdditiveArithmetic where PlaceContent: AdditiveArithmetic {

  /// Initializes a marking with a dictionary, associating `PlaceType.Content.zero` for unassigned
  /// places.
  ///
  /// - Parameters:
  ///   - mapping: A dictionary representing this marking.
  ///
  /// The following example illustrates the use of this initializer:
  ///
  ///     let marking = Marking([.p0: 42])
  ///     print(marking)
  ///     // Prints "[.p0: 42, .p1: 0]"
  ///
  public init(partial mapping: [PlaceType: PlaceContent]) {
    self.storage = TotalMap(partial: mapping, defaultValue: .zero)
  }

  /// A marking in which all places are associated with `PlaceType.Content.zero`.
  public static var zero: Marking {
    return Marking { _ in PlaceContent.zero }
  }

  public static func + (lhs: Marking, rhs: Marking) -> Marking {
    return Marking { key in lhs[key] + rhs[key] }
  }

  public static func += (lhs: inout Marking, rhs: Marking) {
    for place in PlaceType.allCases {
      lhs[place] += rhs[place]
    }
  }

  public static func - (lhs: Marking, rhs: Marking) -> Marking {
    return Marking { place in lhs[place] - rhs[place] }
  }

  public static func -= (lhs: inout Marking, rhs: Marking) {
    for place in PlaceType.allCases {
      lhs[place] -= rhs[place]
    }
  }

}

extension Marking: Collection {

  public typealias Index = TotalMap<PlaceType, PlaceContent>.Index

  public var startIndex: Index {
    storage.startIndex
  }

  public var endIndex: Index {
    storage.endIndex
  }

  public func index(after i: Index) -> Index {
    storage.index(after: i)
  }

  public subscript(i: Index) -> (key: PlaceType, value: PlaceContent) {
    storage[i]
  }

}

extension Marking: CustomStringConvertible {

  public var description: String {
    return String(describing: storage)
  }

}
