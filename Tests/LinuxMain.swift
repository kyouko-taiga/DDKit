import XCTest
@testable import HomomorphismsTests
@testable import WeakSetTests
@testable import YDDTests
@testable import MFDDTests

XCTMain([
    testCase(HomomorphismsTests.allTests),
    testCase(WeakSetTests.allTests),
    testCase(YDDTests.allTests),
    testCase(YDDHomomorphismsTests.allTests),
    testCase(MFDDTests.allTests),
])
