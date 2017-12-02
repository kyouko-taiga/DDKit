import XCTest
@testable import Homomorphisms

class HomomorphismsTests: XCTestCase {

    func testIdentity() {
        let phi = Identity<Set<Int>>()
        XCTAssertEqual(phi.apply(on: [])    , [])
        XCTAssertEqual(phi.apply(on: [1])   , [1])
        XCTAssertEqual(phi.apply(on: [1, 2]), [1, 2])
    }

    func testConstant() {
        let phi = Constant(Set([2, 3]))
        XCTAssertEqual(phi.apply(on: [])    , [2, 3])
        XCTAssertEqual(phi.apply(on: [1])   , [2, 3])
        XCTAssertEqual(phi.apply(on: [1, 2]), [2, 3])
    }

    func testUnion() {
        // Empty union.
        let phi0 = Union<Set<Int>>([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Union of a single homomorphism.
        let phi1 = Union([Constant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Union of multiple homomorphisms.
        let phi2 = Constant(Set([2, 3])) | Identity()
        XCTAssertEqual(phi2.apply(on: [1, 2]), [1, 2, 3])
    }

    func testIntersection() {
        // Empty intersection.
        let phi0 = Intersection<Set<Int>>([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Intersection of a single homomorphism.
        let phi1 = Intersection([Constant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Intersection of multiple homomorphisms.
        let phi2 = Constant(Set([2, 3])) & Identity()
        XCTAssertEqual(phi2.apply(on: [1, 2]), [2])
    }

    func testComposition() {
        // Empty Composition.
        let phi0 = Composition<Set<Int>>([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Composition of a single homomorphism.
        let phi1 = Composition([Constant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Composition of multiple homomorphisms.
        let phi2 = Identity() ° Constant(Set([2, 3]))
        XCTAssertEqual(phi2.apply(on: [1, 2]), [2, 3])
    }

    func testFixedPoint() {
        let phi = (Constant(Set([2, 3])) | Identity())*
        XCTAssertEqual(phi.apply(on: [])    , [2, 3])
        XCTAssertEqual(phi.apply(on: [1])   , [1, 2, 3])
        XCTAssertEqual(phi.apply(on: [1, 2]), [1, 2, 3])
    }

    static var allTests = [
        ("testIdentity"    , testIdentity),
        ("testConstant"    , testConstant),
        ("testUnion"       , testUnion),
        ("testIntersection", testIntersection),
        ("testComposition" , testComposition),
        ("testFixedPoint"  , testFixedPoint),
    ]

}
