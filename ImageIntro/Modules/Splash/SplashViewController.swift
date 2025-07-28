import UIKit
import Foundation
import ProgressHUD

// MARK: - Контроллер загрузочного экрана Splash
final class SplashViewController: UIViewController {
    
    // MARK: - Приватные свойства
    private let ShowAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = KeychainTokenStorage.shared
    private let profileService = ProfileService.shared // ✅ Добавили ссылку на ProfileService
    
    // MARK: - Жизненный цикл
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ SplashViewController загружен")
        
        if let token = KeychainTokenStorage.shared.token {
            print("🔐 Токен найден. Загружаем профиль...")
            fetchProfile(token) // ✅ Заменили switchToTabBarController() на fetchProfile(token)
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
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration")
        }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
    }
}

// MARK: - Подготовка к переходу
extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                fatalError("Failed to prepare for \(ShowAuthenticationScreenSegueIdentifier)")
            }
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
        UIBlockingProgressHUD.show() // ✅ Блокируем UI
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                print("✅ Успешно получили токен. Загружаем профиль...")
                self.fetchProfile(token) // ✅ После токена сразу грузим профиль
            case .failure(let error):
                print("❌ Ошибка получения токена: \(error)")
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    
    // MARK: - Запрос профиля пользователя
    private func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        
        ProfileService.shared.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            switch result {
            case .success(let profile):
                // Стартуем загрузку аватарки, но не ждём результата
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
                
            case .failure(let error):
                print("❌ Ошибка получения профиля: \(error)")
                // TODO: Показать alert об ошибке
            }
        }
    }
}
