import XCTest

/// Adds the widget to the simulator's Home Screen the way a person would, then photographs it.
/// SpringBoard's element names change between iOS releases, so every step attaches what it saw.
final class WidgetUITests: XCTestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testWidgetOnHomeScreen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetData", "-seedSamples"]
        app.launch()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Lisbon,'")).firstMatch.waitForExistence(timeout: 5))

        XCUIDevice.shared.press(.home)
        sleep(1)
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).press(forDuration: 1.5)
        dump("1-after-long-press")

        let edit = springboard.buttons["Edit"]
        if edit.waitForExistence(timeout: 2) {
            edit.tap()
            dump("2-edit-menu")
        }
        let addWidget = springboard.buttons["Add Widget"]
        XCTAssertTrue(addWidget.waitForExistence(timeout: 5), "no Add Widget button")
        addWidget.tap()
        dump("3-gallery")

        let search = springboard.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "no widget search field")
        search.tap()
        search.typeText("Countdown")
        sleep(1)
        dump("4-search")

        let result = springboard.staticTexts.matching(NSPredicate(format: "label == 'Countdown'")).element(boundBy: 1)
        if result.exists { result.tap() } else { springboard.cells.firstMatch.tap() }
        sleep(1)
        dump("5-sizes")

        let add = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add Widget'")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), "no add button on the size picker")
        add.tap()
        sleep(2)
        dump("6-placed")

        let done = springboard.buttons["Done"]
        if done.waitForExistence(timeout: 2) { done.tap() }
        sleep(3)
        snap("widget-home-screen")
    }

    private func dump(_ name: String) {
        let tree = XCTAttachment(string: springboard.debugDescription)
        tree.name = "tree-\(name)"
        tree.lifetime = .keepAlways
        add(tree)
        snap(name)
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
