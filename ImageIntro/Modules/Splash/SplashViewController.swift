import UIKit
import Foundation
import ProgressHUD

// MARK: - Контроллер загрузочного экрана Splash
final class SplashViewController: UIViewController {
    
    
    // MARK: - UI
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "splash_screen_logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    // MARK: - Сервисы
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = KeychainTokenStorage.shared
    private let profileService = ProfileService.shared
    
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        setupLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ SplashViewController загружен")
        
        if let token = oauth2TokenStorage.token {
            print("🔐 Токен найден. Загружаем профиль...")
            fetchProfile(token)
        } else {
            print("🟡 Токен не найден. Запуск авторизации.")
            showAuthFlow()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    
    // MARK: - Верстка
    private func setupLayout() {
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
    // MARK: - Навигация
    private func showAuthFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Не удалось загрузить AuthViewController")
            return
        }
        
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
    
    private func switchToTabBarController() {
        print("🌀 Переход на TabBarController")
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid Configuration")
        }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarController")
        
        window.rootViewController = tabBarController
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
    
    private func fetchOAuthToken(_ code: String) {
        UIBlockingProgressHUD.show()
        oauth2Service.fetchOAuthToken(code: code) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                print("✅ Успешно получили токен. Загружаем профиль...")
                self.fetchProfile(token)
            case .failure(let error):
                print("❌ Ошибка получения токена: \(error)")
                UIBlockingProgressHUD.dismiss()
            }
        }
    }
    
    private func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            print("👀 fetchProfile начал работу")
            
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let profile):
                print("🎉 Успешно получили профиль: \(profile.username)")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()
                
            case .failure(let error):
                switch error {
                case let networkError as NetworkError:
                    switch networkError {
                    case .httpStatusCode(401):
                        print("🔒 Невалидный токен. Удаляем и запускаем авторизацию.")
                        oauth2TokenStorage.removeToken()
                        showAuthFlow()
                    case .httpStatusCode(403):
                        print("⛔️ Доступ запрещён (403). Удаляем токен и запускаем авторизацию.")
                        oauth2TokenStorage.removeToken()
                        showAuthFlow()
                    default:
                        print("🚨 Ошибка сети: \(networkError)")
                    }
                default:
                    print("🚨 Другая ошибка: \(error.localizedDescription)")
                    
                }
            }
        }
    }
}
