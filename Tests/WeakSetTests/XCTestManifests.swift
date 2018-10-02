import XCTest

extension WeakSetTests {
    static let __allTests = [
        ("testAsSequence", testAsSequence),
        ("testCount", testCount),
        ("testEquates", testEquates),
        ("testFormIntersection", testFormIntersection),
        ("testFormSymmetricDifference", testFormSymmetricDifference),
        ("testFormUnion", testFormUnion),
        ("testInitFromSequence", testInitFromSequence),
        ("testInsert", testInsert),
        ("testInsertWithCustomEquality", testInsertWithCustomEquality),
        ("testIntersection", testIntersection),
        ("testIsEmpty", testIsEmpty),
        ("testRemove", testRemove),
        ("testResize", testResize),
        ("testSubtractingSequence", testSubtractingSequence),
        ("testSubtractingWeakSet", testSubtractingWeakSet),
        ("testSubtractingWithPredicate", testSubtractingWithPredicate),
        ("testSubtractSequence", testSubtractSequence),
        ("testSubtractWeakSet", testSubtractWeakSet),
        ("testSubtractWithPredicate", testSubtractWithPredicate),
        ("testSymmetricDifference", testSymmetricDifference),
        ("testUnion", testUnion),
        ("testUpdate", testUpdate),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WeakSetTests.__allTests),
    ]
}
#endif
