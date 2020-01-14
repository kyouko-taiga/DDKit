public protocol DecisionDiagram: Hashable, Sequence, CustomStringConvertible
  where Element: Sequence
{

  associatedtype Pointer: Hashable

  associatedtype Factory: DecisionDiagramFactory where Factory.DD == Self

  var pointer: Pointer { get }

  var factory: Factory { get }

  init(pointer: Pointer, factory: Factory)

}

extension DecisionDiagram {

  /// A Boolean value indicating whether the family is empty.
  public var isEmpty: Bool {
    factory.isEmpty(pointer)
  }

  /// Returns a Boolean value indicating whether this family contains the given member.
  public func contains<S>(_ member: S) -> Bool where S: Sequence, S.Element == Element.Element {
    factory.contains(pointer, member)
  }

  /// Returns a new family with the members of both this family and the given one.
  public func union(_ other: Self) -> Self {
    Self.init(pointer: factory.union(pointer, other.pointer), factory: factory)
  }

  /// Returns a new family with the members of both this family and the given one.
  public func union<Family>(_ other: Family) -> Self
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    union(factory.encode(family: other))
  }

  /// Returns a new family with the members that are common to both this family and the given one.
  public func intersection(_ other: Self) -> Self {
    Self.init(pointer: factory.intersection(pointer, other.pointer), factory: factory)
  }

  /// Returns a new family with the members that are common to both this family and the given one.
  public func intersection<Family>(_ other: Family) -> Self
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    intersection(factory.encode(family: other))
  }

  /// Returns a new family with the members that are either in this family or in the given family,
  /// but not in both.
  public func symmetricDifference(_ other: Self) -> Self {
    Self.init(pointer: factory.symmetricDifference(pointer, other.pointer), factory: factory)
  }

  /// Returns a new family with the members that are either in this family or in the given family,
  /// but not in both.
  public func symmetricDifference<Family>(_ other: Family) -> Self
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    symmetricDifference(factory.encode(family: other))
  }

  /// Returns a new family containing the members of this family that are not in the given family.
  public func subtracting(_ other: Self) -> Self {
    Self.init(pointer: factory.subtraction(pointer, other.pointer), factory: factory)
  }

  /// Returns a new family containing the members of this family that are not in the given family.
  public func subtracting<Family>(_ other: Family) -> Self
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    subtracting(factory.encode(family: other))
  }

  /// Returns a Boolean value that indicates whether this family has no members in common with the
  /// given family.
  public func isDisjoint(with other: Self) -> Bool {
    intersection(other).isEmpty
  }

  /// Returns a Boolean value that indicates whether this family has no members in common with the
  /// given family.
  public func isDisjoint<Family>(with other: Family) -> Bool
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    intersection(other).isEmpty
  }

  /// Returns a Boolean value that indicates whether this family is a strict subset of another
  /// family.
  public func isStrictSubset(of other: Self) -> Bool {
    (self != other) && subtracting(other).isEmpty
  }

  /// Returns a Boolean value that indicates whether this family is a strict subset of another
  /// family.
  public func isStrictSubset<Family>(of other: Family) -> Bool
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    isStrictSubset(of: factory.encode(family: other))
  }

  /// Returns a Boolean value that indicates whether this family is a strict superset of the given
  /// family.
  public func isStrictSuperset(of other: Self) -> Bool {
    (self != other) && other.subtracting(self).isEmpty
  }

  /// Returns a Boolean value that indicates whether this family is a strict superset of the given
  /// family.
  public func isStrictSuperset<Family>(of other: Family) -> Bool
    where Family: Sequence, Family.Element: Sequence, Family.Element.Element == Element.Element
  {
    isStrictSuperset(of: factory.encode(family: other))
  }

  public var description: String {
    let contentDescription = map(String.init(describing:)).joined(separator: ", ")
    return "[\(contentDescription)]"
  }

}
