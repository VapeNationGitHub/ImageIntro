@testable import ImageIntro
import XCTest

// MARK: - Основной класс с тестами
final class WebViewTests: XCTestCase {
    
    // MARK: - Тест 1: проверяем вызов viewDidLoad у презентера
    func testViewControllerCallsViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WebViewViewController") as! WebViewViewController
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        // when
        _ = viewController.view
        
        // then
        XCTAssertTrue(presenter.viewDidLoadCalled, "⚠️ presenter.viewDidLoad() не был вызван")
    }
    
    // MARK: - Тест 2: вызывает ли презентер load(request:)
    func testPresenterCallsLoadRequest() {
        // given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        viewController.presenter = presenter
        presenter.view = viewController
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(viewController.loadRequestCalled, "⚠️ view?.load(request:) не был вызван")
    }
    
    // MARK: - Тест 3: Тестируем необходимость скрытия прогресса
    // Проверка shouldHideProgress (если значение прогресса меньше единицы, то метод возвращает false)
    func testProgressVisibleWhenLessThenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertFalse(shouldHideProgress, "⚠️ Прогресс меньше 1.0, но метод вернул true")
    }
    
    // Проверка shouldHideProgress (если значение прогресса равен единице, то метод возвращает true)
    func testProgressHiddenWhenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0
        
        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        // then
        XCTAssertTrue(shouldHideProgress, "⚠️ Прогресс равен 1.0, но метод вернул false")
    }
    
    // MARK: - Тест 4: Проверяем AuthHelper
    // Проверка URL авторизации
    func testAuthHelperAuthURL() {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        // when
        let url = authHelper.authURL()
        let urlString = url?.absoluteString ?? ""

        // then
        XCTAssertTrue(urlString.contains(configuration.authURLString), "URL не содержит базового адреса авторизации")
        XCTAssertTrue(urlString.contains(configuration.accessKey), "URL не содержит accessKey")
        XCTAssertTrue(urlString.contains(configuration.redirectURI), "URL не содержит redirectURI")
        XCTAssertTrue(urlString.contains("code"), "URL не содержит response_type=code")
        XCTAssertTrue(urlString.contains(configuration.accessScope), "URL не содержит accessScope")
    }
    
    // Проверка извлечения кода из URL
    func testCodeFromURL() {
        // given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()

        // when
        let code = authHelper.code(from: url)

        // then
        XCTAssertEqual(code, "test code", "Код из URL извлечён некорректно")
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

// MARK: - WebViewViewControllerSpy
final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    
    var loadRequestCalled = false
    
    func load(request: URLRequest) {
        loadRequestCalled = true
    }
    
    func setProgressValue(_ newValue: Float) {}
    
    func setProgressHidden(_ isHidden: Bool) {}
}
