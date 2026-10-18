import XCTest

/// Drives the app the way a person would. Run on the simulator:
///     xcodebuild test -scheme Countdown -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
final class CountdownUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func card(_ app: XCUIApplication, titled title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title + ",")).firstMatch
    }

    /// The first save with reminders on asks for notification permission; that alert belongs to
    /// SpringBoard, not the app.
    private func allowNotificationsIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    /// Forms build their lower rows lazily, so an element may not exist until it is scrolled to.
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while !(element.exists && element.isHittable) && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }
    }

    func testCreateEditAndDeleteAnEvent() {
        let app = launch(["-resetData"])
        XCTAssertTrue(app.staticTexts["Nothing to count down to yet"].waitForExistence(timeout: 5))

        // Create from a preset.
        app.buttons["Anniversary"].tap()
        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Our Wedding")
        XCTAssertTrue(app.switches["Repeats every year"].isOn, "the Anniversary preset repeats yearly")
        app.buttons["Save"].tap()
        allowNotificationsIfAsked()

        let created = card(app, titled: "Our Wedding")
        XCTAssertTrue(created.waitForExistence(timeout: 5))
        XCTAssertTrue(created.label.contains("Today"), "dated today, so it reads Today: \(created.label)")

        // Open it.
        created.tap()
        XCTAssertTrue(app.staticTexts["Our Wedding"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Today"].exists)

        // Rename it.
        app.buttons["Edit"].tap()
        let field = app.textFields["titleField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        field.typeText(" Day")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Our Wedding Day"].waitForExistence(timeout: 5))

        // Delete it from the editor; the detail screen closes itself and the list is empty again.
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.textFields["titleField"].waitForExistence(timeout: 5))
        let delete = app.buttons["Delete Event"]
        scrollTo(delete, in: app)
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        app.buttons["Delete “Our Wedding Day”"].tap()
        XCTAssertTrue(app.staticTexts["Nothing to count down to yet"].waitForExistence(timeout: 5))
    }

    func testSwipeToDeleteAsksFirst() {
        let app = launch(["-resetData", "-seedSamples"])
        let marathon = card(app, titled: "Half Marathon")
        XCTAssertTrue(marathon.waitForExistence(timeout: 5))
        scrollTo(marathon, in: app)

        // Cancelling keeps it.
        marathon.swipeLeft()
        app.buttons["Delete"].tap()
        let confirm = app.buttons["Delete “Half Marathon”"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        // An action sheet has a Cancel button; the iOS 26 popover is dismissed by tapping away.
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        }
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 3))
        XCTAssertTrue(marathon.exists)

        marathon.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertTrue(marathon.waitForNonExistence(timeout: 5))
        XCTAssertTrue(card(app, titled: "Lisbon").exists, "the others are untouched")
    }

    func testOneOffEventCountsDownAndPastEventsSitBelow() {
        let app = launch(["-resetData", "-seedSamples"])
        let lisbon = card(app, titled: "Lisbon")
        XCTAssertTrue(lisbon.waitForExistence(timeout: 5))
        XCTAssertTrue(lisbon.label.contains("in 21 days"), lisbon.label)

        let marathon = card(app, titled: "Half Marathon")
        XCTAssertTrue(marathon.label.contains("10 days ago"), marathon.label)
        XCTAssertGreaterThan(marathon.frame.minY, lisbon.frame.minY, "past events sit below upcoming ones")

        let birthday = card(app, titled: "Mom’s Birthday")
        XCTAssertLessThan(birthday.frame.minY, lisbon.frame.minY, "soonest first")
    }

    /// Not a check: the App Store screenshots. Attachments are exported from the .xcresult.
    func testStoreScreenshots() {
        let app = launch(["-resetData", "-seedSamples"])
        let wedding = card(app, titled: "Wedding Anniversary")
        XCTAssertTrue(wedding.waitForExistence(timeout: 5))
        snap("1-list")

        wedding.tap()
        XCTAssertTrue(app.staticTexts["Wedding Anniversary"].waitForExistence(timeout: 5))
        sleep(1)
        snap("2-detail")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Add Event"].tap()
        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.typeText("Graduation\n")
        app.buttons["🎓"].tap()
        sleep(1)
        snap("3-editor")
    }

    private func snap(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}

private extension XCUIElement {
    var isOn: Bool { (value as? String) == "1" }
}
