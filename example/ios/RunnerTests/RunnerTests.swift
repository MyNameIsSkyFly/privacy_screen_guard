import Flutter
import UIKit
import XCTest


@testable import privacy_capture_guard

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testIsEnabledDefaultsToFalse() {
    let plugin = PrivacyCaptureGuardPlugin()

    let call = FlutterMethodCall(methodName: "isEnabled", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as? Bool, false)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
