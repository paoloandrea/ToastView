import XCTest

final class ToastViewExampleUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    func testShowsBasicToast() {
        app.buttons["showMessageButton"].tap()

        let message = app.staticTexts["toastMessageLabel"]
        XCTAssertTrue(message.waitForExistence(timeout: 1.0))
        XCTAssertEqual(message.label, "10:19 AM")
    }

    func testShowsToastWithIcon() {
        app.buttons["showImageAndMessageButton"].tap()

        XCTAssertTrue(app.images["toastIconImageView"].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.staticTexts["toastMessageLabel"].label, "Starred")
    }

    func testShowsProgressToast() {
        app.buttons["showProgressAndMessageButton"].tap()

        XCTAssertTrue(app.activityIndicators["toastActivityIndicator"].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.staticTexts["toastMessageLabel"].label, "Loading...")
    }

    func testShowsBackgroundOverlay() {
        app.buttons["showMessageAndBackgroundButton"].tap()

        XCTAssertTrue(app.otherElements["toastBackgroundOverlay"].waitForExistence(timeout: 1.0))
    }

    func testShowsMultipleToastsWhenEnabled() {
        let button = app.buttons["showMessageButton"]
        button.tap()
        button.tap()

        let messages = app.staticTexts.matching(identifier: "toastMessageLabel")
        XCTAssertTrue(messages.element(boundBy: 1).waitForExistence(timeout: 1.0))
        XCTAssertEqual(messages.count, 2)
    }
}
