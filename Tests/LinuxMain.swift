import XCTest

import HomomorphismsTests
import MFDDTests
import SFDDTests
import WeakSetTests

var tests = [XCTestCaseEntry]()
tests += HomomorphismsTests.__allTests()
tests += MFDDTests.__allTests()
tests += SFDDTests.__allTests()
tests += WeakSetTests.__allTests()

XCTMain(tests)
