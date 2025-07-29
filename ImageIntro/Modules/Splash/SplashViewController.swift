import UIKit

// MARK: - Контроллер загрузочного экрана Splash
final class SplashViewController: UIViewController {
    
    // MARK: - Приватные свойства
    private let ShowAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Жизненный цикл
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("✅ SplashViewController загружен")
        
        // Проверка: есть ли сохранённый токен
        if let token = oauth2TokenStorage.token {
            print("🔐 Токен найден. Переход к TabBar.")
            switchToTabBarController()
        } else {
            print("🟡 Токен не найден. Запуск авторизации.")
            performSegue(withIdentifier: ShowAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Метод перехода к основному TabBar-интерфейсу
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Invalid Configuration") }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? AuthViewController
            else { fatalError("Failed to prepare for \(ShowAuthenticationScreenSegueIdentifier)") }
            print("✅ prepare: делегат назначен напрямую")
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - Делегат авторизации
extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
    }
    
    // MARK: - Запрос токена по коду авторизации
    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                print("✅ Успешно получили токен, переходим к TabBar")
                self.switchToTabBarController()
            case .failure(let error):
                print("❌ Ошибка получения токена: \(error)")
            }
        }
    }
}
