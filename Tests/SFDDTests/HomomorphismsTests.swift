import XCTest
import Homomorphisms
@testable import SFDD

struct Color: Comparable, Hashable {

    let r: Int
    let g: Int
    let b: Int

    static let white     = Color(r: 255, g: 255, b: 255)
    static let lightGray = Color(r: 211, g: 211, b: 211)
    static let darkGray  = Color(r: 128, g: 128, b: 128)
    static let aliceBlue = Color(r: 240, g: 248, b: 255)
    static let indianRed = Color(r: 205, g: 92 , b: 92)

    static func ==(lhs: Color, rhs: Color) -> Bool {
        return (lhs.r == rhs.r) && (lhs.g == rhs.g) && (lhs.b == rhs.b)
    }

    static func <(lhs: Color, rhs: Color) -> Bool {
        return lhs.hashValue < rhs.hashValue
    }

}

class SFDDHomomorphismsTests: XCTestCase {

    func testInsert() {
        let factory    = Factory<Int>()
        let homFactory = SFDDHomomorphismFactory<Int>()

        let phi0 = homFactory.makeInsert([2])
        XCTAssertEqual(phi0.apply(on: factory.zero)     , factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.one)      , factory.make([2]))
        XCTAssertEqual(phi0.apply(on: factory.make([1])), factory.make([1, 2]))
        XCTAssertEqual(phi0.apply(on: factory.make([2])), factory.make([2]))
        XCTAssertEqual(phi0.apply(on: factory.make([3])), factory.make([2, 3]))

        let phi1 = homFactory.makeInsert([2, 3])
        XCTAssertEqual(phi1.apply(on: factory.zero)     , factory.zero)
        XCTAssertEqual(phi1.apply(on: factory.one)      , factory.make([2, 3]))
        XCTAssertEqual(phi1.apply(on: factory.make([1])), factory.make([1, 2, 3]))
        XCTAssertEqual(phi1.apply(on: factory.make([2])), factory.make([2, 3]))
        XCTAssertEqual(phi1.apply(on: factory.make([3])), factory.make([2, 3]))
    }

    func testRemove() {
        let factory    = Factory<Int>()
        let homFactory = SFDDHomomorphismFactory<Int>()

        let phi0 = homFactory.makeRemove([2])
        XCTAssertEqual(phi0.apply(on: factory.zero)        , factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.one)         , factory.one)
        XCTAssertEqual(phi0.apply(on: factory.make([1]))   , factory.make([1]))
        XCTAssertEqual(phi0.apply(on: factory.make([2]))   , factory.one)
        XCTAssertEqual(phi0.apply(on: factory.make([3]))   , factory.make([3]))
        XCTAssertEqual(phi0.apply(on: factory.make([1, 2])), factory.make([1]))

        let phi1 = homFactory.makeRemove([1, 2])
        XCTAssertEqual(phi1.apply(on: factory.zero)        , factory.zero)
        XCTAssertEqual(phi1.apply(on: factory.one)         , factory.one)
        XCTAssertEqual(phi1.apply(on: factory.make([1]))   , factory.one)
        XCTAssertEqual(phi1.apply(on: factory.make([2]))   , factory.one)
        XCTAssertEqual(phi1.apply(on: factory.make([3]))   , factory.make([3]))
        XCTAssertEqual(phi1.apply(on: factory.make([1, 2])), factory.one)
    }

    func testFilter() {
        let factory    = Factory<Int>()
        let homFactory = SFDDHomomorphismFactory<Int>()

        let phi0 = homFactory.makeFilter(containing: [1, 3])
        XCTAssertEqual(phi0.apply(on: factory.zero)        , factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.one)         , factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.make([1]))   , factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.make([1, 3])), factory.make([1, 3]))
        XCTAssertEqual(
            phi0.apply(on: factory.make([1, 2, 3], [1, 4], [2, 3])),
            factory.make([1, 2, 3]))
    }

    func testInductive() {
        let factory    = Factory<Color>()
        let homFactory = SFDDHomomorphismFactory<Color>()

        let colorSets = factory.make([
            [Color.lightGray],
            [Color.lightGray, Color.indianRed, Color.aliceBlue],
            [Color.darkGray , Color.white],
        ])
        let graySets = factory.make([
            [Color.lightGray],
            [Color.darkGray , Color.white],
        ])

        let id  = homFactory.makeIdentity()
        let cut = homFactory.makeConstant(factory.zero)

        let phi0 = homFactory.makeInductive(substitutingOneWith: factory.zero) { _, _ in
            return (cut, cut)
        }
        XCTAssertEqual(phi0.apply(on: factory.zero), factory.zero)
        XCTAssertEqual(phi0.apply(on: factory.one) , factory.zero)
        XCTAssertEqual(phi0.apply(on: colorSets)   , factory.zero)

        let phi1 = homFactory.makeInductive { this, y in
            return (y.key.r == y.key.g) && (y.key.g == y.key.b)
                ? (take: this                  , skip: this)
                : (take: cut, skip: this ° (id | homFactory.makeConstant(y.take)))
        }
        XCTAssertEqual(phi1.apply(on: factory.zero), factory.zero)
        XCTAssertEqual(phi1.apply(on: factory.one) , factory.one)
        XCTAssertEqual(phi1.apply(on: colorSets)   , graySets)
    }

}
