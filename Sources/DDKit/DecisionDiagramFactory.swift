public protocol DecisionDiagramFactory: AnyObject {

  associatedtype DD: DecisionDiagram

  /// Returns a decision diagram that encodes the given family.
  ///
  /// - Parameter family: The family to encode as a decision diagram.
  ///
  /// - Returns: The decision diagram that encodes the given family.
  func encode<S>(family: S) -> DD
    where S: Sequence, S.Element: Sequence, S.Element.Element == DD.Element.Element

  /// A Boolean value indicating whether the given family has no member.
  func isEmpty(_ pointer: DD.Pointer) -> Bool

  /// Returns a Boolean value indicating whether the given family contains the given member.
  func contains<S>(_ pointer: DD.Pointer, _ member: S) -> Bool
    where S: Sequence, S.Element == DD.Element.Element

  /// Returns the union of two decision diagrams.
  func union(_ lhs: DD.Pointer, _ rhs: DD.Pointer) -> DD.Pointer

  /// Returns the intersection of two dicision diagrams.
  func intersection(_ lhs: DD.Pointer, _ rhs: DD.Pointer) -> DD.Pointer

  /// Returns the symmetric difference (a.k.a. disjunctive union) between two decision diagrams.
  func symmetricDifference(_ lhs: DD.Pointer, _ rhs: DD.Pointer) -> DD.Pointer

  /// Returns a given decision diagram subtracted by another.
  func subtraction(_ lhs: DD.Pointer, _ rhs: DD.Pointer) -> DD.Pointer

}
