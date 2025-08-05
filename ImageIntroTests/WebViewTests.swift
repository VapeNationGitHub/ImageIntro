@testable import ImageIntro
import XCTest

// MARK: - Основной класс с тестами
final class WebViewTests: XCTestCase {

    // MARK: - Тест: проверяем вызов viewDidLoad у презентера
    func testViewControllerCallsViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        _ = viewController.view // это вызовет viewDidLoad()

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled, "⚠️ presenter.viewDidLoad() не был вызван")
    }
}

// MARK: - Шпион для WebViewPresenter
final class WebViewPresenterSpy: WebViewPresenterProtocol {
    var viewDidLoadCalled: Bool = false
    var view: WebViewViewControllerProtocol?

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didUpdateProgressValue(_ newValue: Double) {}

    func code(from url: URL) -> String? {
        return nil
    }
}
