import XCTest

final class tvToastViewExampleUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    func testShowsBasicToast() {
        selectButton(at: 0)

        let message = app.staticTexts["toastMessageLabel"]
        XCTAssertTrue(message.waitForExistence(timeout: 1.0))
        XCTAssertEqual(message.label, "10:19 AM")
    }

    func testShowsToastWithIcon() {
        selectButton(at: 1)

        XCTAssertTrue(app.images["toastIconImageView"].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.staticTexts["toastMessageLabel"].label, "Starred")
    }

    func testShowsProgressToast() {
        selectButton(at: 2)

        XCTAssertTrue(app.activityIndicators["toastActivityIndicator"].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.staticTexts["toastMessageLabel"].label, "Loading...")
    }

    func testShowsBackgroundOverlay() {
        selectButton(at: 3)

        XCTAssertTrue(app.otherElements["toastBackgroundOverlay"].waitForExistence(timeout: 1.0))
    }

    private func selectButton(at index: Int) {
        let remote = XCUIRemote.shared
        for _ in 0..<index {
            remote.press(.down)
        }
        remote.press(.select)
    }
}
