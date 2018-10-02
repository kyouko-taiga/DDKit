import XCTest

import HomomorphismsTests
import MFDDTests
import WeakSetTests
import YDDTests

var tests = [XCTestCaseEntry]()
tests += HomomorphismsTests.__allTests()
tests += MFDDTests.__allTests()
tests += WeakSetTests.__allTests()
tests += YDDTests.__allTests()

XCTMain(tests)
