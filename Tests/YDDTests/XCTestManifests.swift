import XCTest

extension YDDHomomorphismsTests {
    static let __allTests = [
        ("testFilter", testFilter),
        ("testInductive", testInductive),
        ("testInsert", testInsert),
        ("testRemove", testRemove),
    ]
}

extension YDDTests {
    static let __allTests = [
        ("testAsSequence", testAsSequence),
        ("testContains", testContains),
        ("testCount", testCount),
        ("testEquates", testEquates),
        ("testIntersection", testIntersection),
        ("testSubtracting", testSubtracting),
        ("testSymmetricDifference", testSymmetricDifference),
        ("testUnion", testUnion),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(YDDHomomorphismsTests.__allTests),
        testCase(YDDTests.__allTests),
    ]
}
#endif
