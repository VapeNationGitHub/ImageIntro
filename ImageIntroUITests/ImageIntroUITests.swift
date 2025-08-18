import XCTest
import CoreGraphics

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication() // переменная приложения
    
    override func setUpWithError() throws {
        continueAfterFailure = false // настройка выполнения тестов, которая прекратит выполнения тестов, если в тесте что-то пошло не так
        
        app.launchArguments += ["--ui-tests"]
        
        app.launch() // запускаем приложение перед каждым тестом
    }
    
    // MARK: - Авторизация в приложение
    func testAuth() throws {
        app.buttons["Войти"].tap()
        
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 10))
        
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        
        loginTextField.tap()
        loginTextField.typeText("example@gmail.com")
        
        let nextButton = app.buttons.element(boundBy: 1)
        if nextButton.exists {
            nextButton.tap()
        }
        
        // Ввод пароля через буфер обмена
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        
        // Вставка из буфера обмена
        UIPasteboard.general.string = "password"
        passwordTextField.press(forDuration: 1.2)
        
        let pasteButton = app.menuItems["Paste"]
        if pasteButton.waitForExistence(timeout: 2) {
            pasteButton.tap()
        } else {
            XCTFail("Кнопка 'Paste' не найдена")
        }
        
        let loginButton = webView.buttons["Login"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    
    // MARK: - Работа с лентой
    func testFeed() throws {
        let tablesQuery = app.tables
        
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        cell.swipeUp()
        
        sleep(2)
        
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: 1)
        
        cellToLike.buttons["likeButtonOff"].tap()
        cellToLike.buttons["likeButtonOn"].tap()
        
        sleep(2)
        
        cellToLike.tap()
        
        sleep(2)
        
        let image = app.scrollViews.images.element(boundBy: 0)
        // Zoom in
        image.pinch(withScale: 3, velocity: 1) // zoom in
        // Zoom out
        image.pinch(withScale: 0.5, velocity: -1)
        
        let navBackButtonWhiteButton = app.buttons["nav back button white"]
        navBackButtonWhiteButton.tap()
    }
    
    // MARK: - Работа с профилем
    func testProfile() throws {
        sleep(1)
        app.tabBars.buttons.element(boundBy: 1).tap()
        
        XCTAssertTrue(app.staticTexts["FirstName SecondName"].exists)
        XCTAssertTrue(app.staticTexts["@UserName"].exists)
        
        app.buttons["Exit"].tap()
        
        app.alerts["Пока, пока!"].scrollViews.otherElements.buttons["Да"].tap()
    }
}


extension XCUIElement {
    /// Ждём, пока элемент будет и существовать, и быть кликабельным
    func waitForHittable(timeout: TimeInterval) -> Bool {
        let p = NSPredicate(format: "exists == true AND hittable == true")
        let exp = XCTNSPredicateExpectation(predicate: p, object: self)
        return XCTWaiter().wait(for: [exp], timeout: timeout) == .completed
    }
    
    /// Доскроллить таблицу, пока элемент не станет hittable
    func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            swipeUp()
            swipes += 1
        }
    }
}
