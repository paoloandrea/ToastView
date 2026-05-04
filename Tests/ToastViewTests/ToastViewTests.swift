import XCTest
@testable import ToastView

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
final class ToastViewTests: XCTestCase {

    var window: UIWindow!
    var manager: ToastManager!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        manager = ToastManager.shared
        manager.cancelAllToasts()
        manager.allowMultipleToasts = false
    }

    override func tearDown() {
        manager.cancelAllToasts()
        window.isHidden = true
        window = nil
        super.tearDown()
    }

    func testShowToastSetsCurrentlyShowing() {
        manager.showToast(message: "Hello, World!", duration: 0, in: window.rootViewController!.view)
        XCTAssertTrue(manager.isCurrentlyShowing, "A toast should be marked as visible after showToast.")
    }

    func testShowToastWithImage() {
        let image = UIImage(systemName: "star.fill")
        manager.showToast(message: "Starred", image: image, duration: 0, in: window.rootViewController!.view)
        XCTAssertTrue(manager.isCurrentlyShowing, "Toast with image should be visible.")
    }

    func testCancelCurrentToast() {
        manager.showToast(message: "Hello, World!", duration: 0, in: window.rootViewController!.view)
        manager.cancelCurrentToast()

        let expectation = XCTestExpectation(description: "Dismiss animation completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.manager.isCurrentlyShowing, "All toasts should be dismissed.")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSingleToastGuard() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = false
        manager.showToast(message: "First", duration: 0, in: view)
        manager.showToast(message: "Second (ignored)", duration: 0, in: view)
        XCTAssertTrue(manager.isCurrentlyShowing)
        // Only the first toast should have been added; second call is a no-op.
        XCTAssertEqual(view.subviews.compactMap { $0 as? ToastView }.count, 1)
    }

    func testMultipleToastsStacking() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "First", duration: 0, in: view)
        manager.showToast(message: "Second", duration: 0, in: view)
        XCTAssertEqual(view.subviews.compactMap { $0 as? ToastView }.count, 2)
    }

    func testUpdateMessageInPlace() {
        manager.showToast(message: "Initial", duration: 0, in: window.rootViewController!.view)
        manager.message = "Updated"
        XCTAssertEqual(manager.message, "Updated")
    }
}
#endif
