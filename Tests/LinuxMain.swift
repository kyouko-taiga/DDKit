import XCTest
@testable import HomomorphismsTests
@testable import WeakSetTests
@testable import YDDTests

XCTMain([
    testCase(HomomorphismsTests.allTests),
    testCase(WeakSetTests.allTests),
    testCase(YDDTests.allTests),
    testCase(YDDHomomorphismsTests.allTests),
])
