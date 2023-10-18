import XCTest
@testable import ToastView

@available(iOS 13.0, *)
final class ToastViewTests: XCTestCase {
    var window: UIWindow!
    
    override func setUp() {
        super.setUp()
        window = UIWindow()
        window.rootViewController = UIViewController()
        window.isHidden = false
    }
    
    override func tearDown() {
        window = nil
        super.tearDown()
    }
    
    /// Tests whether the ToastView can be presented with just a message.
    
    func testShowWithMessage() {
        ToastView.show(message: "Hello, World!", in: window.rootViewController!.view)
        XCTAssertTrue(ToastView.activeToasts.count == 1, "Toast should be presented.")
    }
    
    /// Tests whether the ToastView can be presented with a message and an image.
    func testShowWithMessageAndImage() {
        let image = UIImage(systemName: "star.fill")
        ToastView.show(message: "Hello, World!", image: image, in: window.rootViewController!.view)
        XCTAssertTrue(ToastView.activeToasts.count == 1, "Toast with image should be presented.")
    }
    
    /// Tests whether the ToastView can be dismissed manually.
    func testManualDismissal() {
        ToastView.show(message: "Hello, World!", in: window.rootViewController!.view)
        ToastView.dismiss()
        XCTAssertTrue(ToastView.activeToasts.isEmpty, "All toasts should be dismissed.")
    }
}
