import XCTest
@testable import WeakSet

class TestElement: Hashable {

    init(_ value: Int) {
        self.value = value
    }

    let value: Int

    var hashValue: Int {
        return self.value
    }

    static func ==(lhs: TestElement, rhs: TestElement) -> Bool {
        return lhs.value == rhs.value
    }

}

class WeakSetTests: XCTestCase {

    func testInitFromSequence() {
        var elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements)

        XCTAssertEqual(set.count, 100)

        elements = []
        XCTAssertEqual(set.count, 0)
    }

    func testInsert() {
        var set = WeakSet<TestElement>()
        var insertResult: (inserted: Bool, memberAfterInsert: TestElement)

        let e0 = TestElement(0)
        insertResult = set.insert(e0)
        XCTAssertTrue(insertResult.inserted)
        XCTAssert(insertResult.memberAfterInsert === e0)

        let e1 = TestElement(0)
        insertResult = set.insert(e1)
        XCTAssertFalse(insertResult.inserted)
        XCTAssert(insertResult.memberAfterInsert === e0)
    }

    func testInsertWithCustomEquality() {
        var set = WeakSet<TestElement>()
        var insertResult: (inserted: Bool, memberAfterInsert: TestElement)

        let e0 = TestElement(0)
        insertResult = set.insert(e0, withCustomEquality: { (_, _) in false })
        XCTAssertTrue(insertResult.inserted)
        XCTAssert(insertResult.memberAfterInsert === e0)

        let e1 = TestElement(0)
        insertResult = set.insert(e1, withCustomEquality: { (_, _) in false })
        XCTAssertTrue(insertResult.inserted)
        XCTAssert(insertResult.memberAfterInsert === e1)
    }

    func testUpdate() {
        var set = WeakSet<TestElement>()
        var memberAfterUpdate: TestElement?

        let e0 = TestElement(0)
        memberAfterUpdate = set.update(with: e0)
        XCTAssertNil(memberAfterUpdate)

        let e1 = TestElement(0)
        memberAfterUpdate = set.update(with: e1)
        XCTAssert(memberAfterUpdate === e0)
    }

    func testRemove() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements)
        var removeResult: TestElement?

        removeResult = set.remove(TestElement(0))
        XCTAssertEqual(removeResult, elements[0])

        removeResult = set.remove(TestElement(0))
        XCTAssertNil(removeResult)
    }

    func testResize() {
        var set = WeakSet<TestElement>()
        var oldCapacity: Int

        oldCapacity = set.capacity
        set.resize()
        XCTAssertEqual(set.capacity, oldCapacity)

        oldCapacity = set.capacity
        set.resize(minimumCapacity: oldCapacity - 1)
        XCTAssertEqual(set.capacity, oldCapacity)

        oldCapacity = set.capacity
        set.resize(minimumCapacity: -1)
        XCTAssertEqual(set.capacity, oldCapacity)

        oldCapacity = set.capacity
        set.resize(minimumCapacity: oldCapacity * 2)
        XCTAssertEqual(set.capacity, oldCapacity * 2)
    }

    func testIsEmpty() {
        var set = WeakSet<TestElement>()
        XCTAssertTrue(set.isEmpty)

        var e0: TestElement? = TestElement(0)
        set.insert(e0!)
        XCTAssertFalse(set.isEmpty)

        e0 = nil
        XCTAssertTrue(set.isEmpty)
    }

    func testCount() {
        var set = WeakSet<TestElement>()
        XCTAssertEqual(set.count, 0)

        var e0: TestElement? = TestElement(0)
        set.insert(e0!)
        XCTAssertEqual(set.count, 1)

        let e1 = TestElement(1)
        set.insert(e1)
        XCTAssertEqual(set.count, 2)

        e0 = nil
        XCTAssertEqual(set.count, 1)
    }

    func testEquates() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var lhs = WeakSet(elements)
        let rhs = WeakSet(elements)

        XCTAssertEqual(lhs, rhs)

        lhs.remove(TestElement(0))
        XCTAssertNotEqual(lhs, rhs)
    }

    func testUnion() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements[0 ..< 50]).union(elements[50 ..< 100])
        XCTAssertEqual(set, WeakSet(elements))
    }

    func testFormUnion() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements[0 ..< 50])
        set.formUnion(elements[50 ..< 100])
        XCTAssertEqual(set, WeakSet(elements))
    }

    func testIntersection() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set0 = WeakSet(elements[0 ..< 50]).intersection(elements[25 ..< 75])
        XCTAssertEqual(set0, WeakSet(elements[25 ..< 50]))

        let set1 = WeakSet(elements[0 ..< 50]).intersection(elements[50 ..< 100])
        XCTAssertEqual(set1, WeakSet())
    }

    func testFormIntersection() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set0 = WeakSet(elements[0 ..< 50])
        set0.formIntersection(elements[25 ..< 75])
        XCTAssertEqual(set0, WeakSet(elements[25 ..< 50]))

        var set1 = WeakSet(elements[0 ..< 50])
        set1.formIntersection(elements[50 ..< 100])
        XCTAssertEqual(set1, WeakSet())
    }

    func testSymmetricDifference() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements[0 ..< 50]).symmetricDifference(elements[25 ..< 75])
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25] + elements[50 ..< 75]))
    }

    func testFormSymmetricDifference() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements[0 ..< 50])
        set.formSymmetricDifference(elements[25 ..< 75])
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25] + elements[50 ..< 75]))
    }

    func testSubtractingWeakSet() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements[0 ..< 50]).subtracting(WeakSet(elements[25 ..< 75]))
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
    }

    func testSubtractingSequence() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements[0 ..< 50]).subtracting(elements[25 ..< 75])
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
    }

    func testSubtractingWithPredicate() {
        let elements = (0 ..< 100).map { TestElement($0) }
        let set = WeakSet(elements[0 ..< 50]).subtracting(where: { 25 ..< 75 ~= $0.value })
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
    }

    func testSubtractWeakSet() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements[0 ..< 50])
        set.subtract(WeakSet(elements[25 ..< 75]))
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
    }

    func testSubtractSequence() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements[0 ..< 50])
        set.subtract(elements[25 ..< 75])
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
    }

    func testSubtractWithPredicate() {
        let elements = (0 ..< 100).map { TestElement($0) }
        var set = WeakSet(elements[0 ..< 50])
        var subtractResult: [TestElement]

        subtractResult = set.subtract(where: { 25 ..< 75 ~= $0.value })
        XCTAssertEqual(set, WeakSet(elements[0 ..< 25]))
        XCTAssertEqual(Set(subtractResult), Set(elements[25 ..< 50]))
    }

    func testAsSequence() {
        var elements = (0 ..< 200).map { TestElement($0) }

        XCTAssertEqual(Set(elements), Set(WeakSet(elements)))

        let set = WeakSet(elements)
        elements = Array(elements.dropFirst(100))
        XCTAssertEqual(Set(elements), Set(set))
    }

    static var allTests = [
        ("testInitFromSequence"        , testInitFromSequence),
        ("testInsert"                  , testInsert),
        ("testInsertWithCustomEquality", testInsertWithCustomEquality),
        ("testUpdate"                  , testUpdate),
        ("testRemove"                  , testRemove),
        ("testResize"                  , testResize),
        ("testIsEmpty"                 , testIsEmpty),
        ("testCount"                   , testCount),
        ("testEquates"                 , testEquates),
        ("testUnion"                   , testUnion),
        ("testFormUnion"               , testFormUnion),
        ("testIntersection"            , testIntersection),
        ("testFormIntersection"        , testFormIntersection),
        ("testSymmetricDifference"     , testSymmetricDifference),
        ("testFormSymmetricDifference" , testFormSymmetricDifference),
        ("testSubtractingWeakSet"      , testSubtractingWeakSet),
        ("testSubtractingSequence"     , testSubtractingSequence),
        ("testSubtractingWithPredicate", testSubtractingWithPredicate),
        ("testSubtractWeakSet"         , testSubtractWeakSet),
        ("testSubtractSequence"        , testSubtractSequence),
        ("testSubtractWithPredicate"   , testSubtractWithPredicate),
        ("testAsSequence"              , testAsSequence),
    ]

}
