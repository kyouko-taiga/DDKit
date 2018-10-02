import XCTest

extension MFDDTests {
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
        testCase(MFDDTests.__allTests),
    ]
}
#endif
