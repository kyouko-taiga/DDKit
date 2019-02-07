import XCTest
@testable import Utils

class HashingTests: XCTestCase {

  func testFNV1() {
    let a = [1, 2, 3]
    let b = [1, 2, 3]
    XCTAssertEqual(fnv1(data: a, size: 3), fnv1(data: b, size: 3))

    let c = [3, 2, 1]
    XCTAssertNotEqual(fnv1(data: a, size: 3), fnv1(data: c, size: 3))
  }

}
