import XCTest
import DDKit

final class NQueensTests: XCTestCase {

  func testFourQueens() {
    let factory = SFDDFactory<Int>(bucketCapacity: 128)
    let chessboard = nQueens(queenCount: 4, factory: factory)
    XCTAssertEqual(chessboard.count, 2)
  }

  func testEightQueens() {
    let factory = SFDDFactory<Int>(bucketCapacity: 8192)
    let chessboard = nQueens(queenCount: 8, factory: factory)
    XCTAssertEqual(chessboard.count, 92)
  }

}

private func nQueens(queenCount: Int, factory: SFDDFactory<Int>) -> SFDD<Int> {

  typealias SaturatedRemove = SFDD<Int>.SaturatedMorphism<SFDD<Int>.Remove>

  let identity = factory.morphisms.identity
  let zero = factory.morphisms.constant(factory.zero)

  /// A helper function to create cell indices.
  func cell(row: Int, column: Int) -> Int {
    return row * queenCount + column
  }

  /// A helper function to extract coordinates from a cell index.
  func rowColumn(at index: Int) -> (row: Int, column: Int) {
    return (row: index / queenCount, column: index % queenCount)
  }

  // Precompute the set of indices to remove and generate the corresponding morphisms.
  let indicesToRemove = Dictionary(
    uniqueKeysWithValues: (0 ..< queenCount * queenCount - 1)
      .map({ (key: Int) -> (Int, SaturatedRemove) in
        let cell = rowColumn(at: key)
        let indicesToRemove = (key + 1 ..< queenCount * queenCount).filter({ i in
          let other = rowColumn(at: i)
          return cell.row == other.row
              || cell.column == other.column
              || abs(cell.row - other.row) == abs(cell.column - other.column)
          })
        return (key, factory.morphisms.saturate(factory.morphisms.remove(keys: indicesToRemove)))
      }))

  /// Creates an morphism that filter a checkboard to keep only the possible configurations that
  /// position n queens that can't attack each others.
  func filterValidConfigurations(from row: Int = 0) -> SFDD<Int>.Inductive? {
    guard row < queenCount
      else { return nil }

    // Precompute the inductive morphisms to apply at each step.
    let nextFilter = filterValidConfigurations(from: row + 1)
    let next = indicesToRemove.mapValues({
      (remove: SaturatedRemove) -> (SFDD<Int>.Inductive) -> SFDD<Int>.Inductive.Result in

      let take: (SFDD<Int>.Pointer) -> SFDD<Int>.Pointer
      if let filter = nextFilter {
        take = factory.morphisms.composition(of: filter, with: remove).apply(on:)
      } else {
        take = remove.apply(on:)
      }

      return { (this: SFDD<Int>.Inductive) in (take: take, skip: this.apply(on:)) }
    })

    // Create an inductive morphism that:
    // - Ensures the presence of a single queen on a given row.
    // - Removes the configurations that are not compatible with the presence of a queen at a
    //   specific location.
    let upperBound = queenCount * queenCount - 1
    return factory.morphisms.inductive(
      substitutingOneWith: factory.zero,
      function: { this, pointer in
        // The current key corresponds to a location from the next row, therefore indicating that
        // there was no queen on the current row.
        guard pointer.pointee.key / queenCount <= row
          else { return (take: zero.apply(on:), skip: zero.apply(on:)) }

        // If there's a valid queen positioned on the last cell, we can keep the one terminal on
        // the take branch and reject the skip branch.
        guard pointer.pointee.key < upperBound
          else { return (take: identity.apply(on:), skip: zero.apply(on:)) }

        // Recursively apply this morphism for the next cell of the chessboard.
        return next[pointer.pointee.key]!(this)
      })
  }

  // Build all possible configurations.
  var chessboard = factory.one
  chessboard = (0 ..< queenCount * queenCount)
    .reversed()
    .reduce(chessboard) { (dd: SFDD<Int>, index: Int) -> SFDD<Int> in
      SFDD(pointer: factory.node(key: index, take: dd.pointer, skip: dd.pointer), factory: factory)
    }

  let morphism = filterValidConfigurations()
  let ptr = morphism.map({ $0.apply(on: chessboard.pointer) }) ?? chessboard.pointer
  return SFDD(pointer: ptr, factory: factory)
}
