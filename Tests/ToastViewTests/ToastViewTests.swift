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
        let view = window.rootViewController!.view!
        manager.showToast(message: "Starred", image: image, duration: 0, in: view)

        let toast = view.subviews.compactMap { $0 as? ToastView }.first
        XCTAssertNotNil(allImageViews(in: toast).first(where: { $0.accessibilityIdentifier == "toastIconImageView" }))
    }

    func testShowToastWithProgressIndicator() {
        let view = window.rootViewController!.view!
        manager.showToast(message: "Loading", isProgress: true, duration: 0, in: view)

        let toast = view.subviews.compactMap { $0 as? ToastView }.first
        XCTAssertNotNil(allActivityIndicators(in: toast).first)
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

    func testAutoDismissClearsQueueAndAllowsAnotherToast() {
        let view = window.rootViewController!.view!
        manager.showToast(message: "First", duration: 0.01, in: view)

        let expectation = XCTestExpectation(description: "Auto-dismiss clears queue")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            XCTAssertFalse(self.manager.isCurrentlyShowing)

            self.manager.showToast(message: "Second", duration: 0, in: view)
            XCTAssertTrue(self.manager.isCurrentlyShowing)
            XCTAssertEqual(view.subviews.compactMap { $0 as? ToastView }.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.5)
    }

    func testCenterToastsKeepSingleVerticalConstraintEach() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "First", position: .center, duration: 0, in: view)
        manager.showToast(message: "Second", position: .center, duration: 0, in: view)

        let toasts = view.subviews.compactMap { $0 as? ToastView }
        XCTAssertEqual(toasts.count, 2)

        for toast in toasts {
            XCTAssertEqual(verticalConstraints(for: toast, in: view, matching: .centerY).count, 1)
        }
    }

    func testAutoDismissReflowsRemainingToasts() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "Persistent", position: .top, duration: 0, in: view)
        manager.showToast(message: "Temporary", position: .top, duration: 0.01, in: view)

        let expectation = XCTestExpectation(description: "Remaining toast moves to top edge")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let toasts = view.subviews.compactMap { $0 as? ToastView }
            XCTAssertEqual(toasts.count, 1)
            guard let toast = toasts.first else {
                XCTFail("A persistent toast should remain after the temporary toast auto-dismisses.")
                expectation.fulfill()
                return
            }

            let topConstraint = self.verticalConstraints(for: toast, in: view, matching: .top).first
            XCTAssertEqual(topConstraint?.constant, ToastView.edgePadding)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.5)
    }

    func testMixedVerticalPositionsUseIndependentOffsets() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "Bottom", position: .bottom, duration: 0, in: view)
        manager.showToast(message: "Top", position: .top, duration: 0, in: view)

        let toasts = view.subviews.compactMap { $0 as? ToastView }
        XCTAssertEqual(toasts.count, 2)

        let topToast = toasts.first(where: { $0.position == .top })
        let bottomToast = toasts.first(where: { $0.position == .bottom })

        XCTAssertEqual(topToast.flatMap { verticalConstraints(for: $0, in: view, matching: .top).first }?.constant,
                       ToastView.edgePadding)
        XCTAssertEqual(bottomToast.flatMap { verticalConstraints(for: $0, in: view, matching: .bottom).first }?.constant,
                       -ToastView.edgePadding)
    }

    func testForcedAboveTabBarUsesFallbackOffsetWithoutTabBar() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "Forced", position: .bottomAboveTabBar, duration: 0, in: view)

        let toast = view.subviews.compactMap { $0 as? ToastView }.first
        let constraint = toast.flatMap { verticalConstraints(for: $0, in: view, matching: .bottom).first }
        XCTAssertEqual(constraint?.constant, -(ToastView.edgePadding + ToastView.fallbackTabBarOffset))
    }

    func testCancelAllToastsClearsVisibleToastsAndManagerState() {
        let view = window.rootViewController!.view!
        manager.allowMultipleToasts = true
        manager.showToast(message: "First", duration: 0, in: view)
        manager.showToast(message: "Second", duration: 0, in: view)

        manager.cancelAllToasts()

        let expectation = XCTestExpectation(description: "All dismiss animations complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.manager.isCurrentlyShowing)
            XCTAssertTrue(view.subviews.compactMap { $0 as? ToastView }.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBackgroundOverlayIsRemovedWithToast() {
        let view = window.rootViewController!.view!
        manager.showToast(message: "Overlay", duration: 0, in: view, withBackground: true)
        XCTAssertNotNil(view.subviews.first(where: { $0.accessibilityIdentifier == "toastBackgroundOverlay" }))

        manager.cancelCurrentToast()

        let expectation = XCTestExpectation(description: "Background overlay removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(view.subviews.first(where: { $0.accessibilityIdentifier == "toastBackgroundOverlay" }))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBottomToastAccountsForVisibleTabBar() {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [UIViewController()]
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        tabBarController.view.layoutIfNeeded()

        let view = tabBarController.view!
        manager.showToast(message: "Bottom", position: .bottom, duration: 0, in: view)

        let expectedOffset = view.toast_tabBarOffset()
        let toast = view.subviews.compactMap { $0 as? ToastView }.first
        let constraint = toast.flatMap { verticalConstraints(for: $0, in: view, matching: .bottom).first }

        XCTAssertGreaterThan(expectedOffset, 0)
        XCTAssertEqual(constraint?.constant, -(ToastView.edgePadding + expectedOffset))
    }

    func testUpdateMessageInPlace() {
        let view = window.rootViewController!.view!
        manager.showToast(message: "Initial", duration: 0, in: view)
        manager.message = "Updated"

        let toast = view.subviews.compactMap { $0 as? ToastView }.first
        XCTAssertEqual(allLabels(in: toast).first?.text, "Updated")
    }

    private func verticalConstraints(for toast: ToastView,
                                     in view: UIView,
                                     matching attribute: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        view.constraints.filter { constraint in
            constraint.isActive &&
            constraint.firstItem as? UIView === toast &&
            constraint.firstAttribute == attribute
        }
    }

    private func allLabels(in view: UIView?) -> [UILabel] {
        guard let view = view else { return [] }
        let labels = view.subviews.compactMap { $0 as? UILabel }
        return labels + view.subviews.flatMap { allLabels(in: $0) }
    }

    private func allImageViews(in view: UIView?) -> [UIImageView] {
        guard let view = view else { return [] }
        let imageViews = view.subviews.compactMap { $0 as? UIImageView }
        return imageViews + view.subviews.flatMap { allImageViews(in: $0) }
    }

    private func allActivityIndicators(in view: UIView?) -> [UIActivityIndicatorView] {
        guard let view = view else { return [] }
        let activityIndicators = view.subviews.compactMap { $0 as? UIActivityIndicatorView }
        return activityIndicators + view.subviews.flatMap { allActivityIndicators(in: $0) }
    }
}
#endif
