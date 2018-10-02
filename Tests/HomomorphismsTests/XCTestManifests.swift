import XCTest

extension HomomorphismsTests {
    static let __allTests = [
        ("testComposition", testComposition),
        ("testConstant", testConstant),
        ("testFixedPoint", testFixedPoint),
        ("testIdentity", testIdentity),
        ("testIntersection", testIntersection),
        ("testUnion", testUnion),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(HomomorphismsTests.__allTests),
    ]
}
#endif
