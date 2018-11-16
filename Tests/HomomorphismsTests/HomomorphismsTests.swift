import XCTest
@testable import Homomorphisms

extension Set: ImmutableSetAlgebra {}

class HomomorphismsTests: XCTestCase {

    func testIdentity() {
        let factory = HomomorphismFactory<Set<Int>>()
        let phi = factory.makeIdentity()
        XCTAssertEqual(phi.apply(on: [])    , [])
        XCTAssertEqual(phi.apply(on: [1])   , [1])
        XCTAssertEqual(phi.apply(on: [1, 2]), [1, 2])
    }

    func testConstant() {
        let factory = HomomorphismFactory<Set<Int>>()
        let phi = factory.makeConstant(Set([2, 3]))
        XCTAssertEqual(phi.apply(on: [])    , [2, 3])
        XCTAssertEqual(phi.apply(on: [1])   , [2, 3])
        XCTAssertEqual(phi.apply(on: [1, 2]), [2, 3])
    }

    func testUnion() {
        let factory = HomomorphismFactory<Set<Int>>()

        // Empty union.
        let phi0 = factory.makeUnion([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Union of a single homomorphism.
        let phi1 = factory.makeUnion([factory.makeConstant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Union of multiple homomorphisms.
        let phi2 = factory.makeConstant(Set([2, 3])) | factory.makeIdentity()
        XCTAssertEqual(phi2.apply(on: [1, 2]), [1, 2, 3])
    }

    func testIntersection() {
        let factory = HomomorphismFactory<Set<Int>>()

        // Empty intersection.
        let phi0 = factory.makeIntersection([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Intersection of a single homomorphism.
        let phi1 = factory.makeIntersection([factory.makeConstant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Intersection of multiple homomorphisms.
        let phi2 = factory.makeConstant(Set([2, 3])) & factory.makeIdentity()
        XCTAssertEqual(phi2.apply(on: [1, 2]), [2])
    }

    func testComposition() {
        let factory = HomomorphismFactory<Set<Int>>()

        // Empty Composition.
        let phi0 = factory.makeComposition([])
        XCTAssertEqual(phi0.apply(on: [1, 2]), [1, 2])

        // Composition of a single homomorphism.
        let phi1 = factory.makeComposition([factory.makeConstant(Set([2, 3]))])
        XCTAssertEqual(phi1.apply(on: [1, 2]), [2, 3])

        // Composition of multiple homomorphisms.
        let phi2 = factory.makeIdentity() ° factory.makeConstant(Set([2, 3]))
        XCTAssertEqual(phi2.apply(on: [1, 2]), [2, 3])
    }

    func testFixedPoint() {
        let factory = HomomorphismFactory<Set<Int>>()
        let phi = (factory.makeConstant(Set([2, 3])) | factory.makeIdentity())*
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
