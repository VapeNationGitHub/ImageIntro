import UIKit

// MARK: - Протокол делегата
protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

// MARK: - Контроллер авторизации
final class AuthViewController: UIViewController {
    private let showWebViewIdentifier = "ShowWebViewSegue"
    // private let oauth2Service = OAuth2Service.shared

    weak var delegate: AuthViewControllerDelegate?
    
    // 👇 Метод для обработки кнопки
    @IBAction private func didTapLoginButton(_ sender: UIButton) {
        performSegue(withIdentifier: showWebViewIdentifier, sender: nil)
    }

    // MARK: - Подготовка к переходу на WebView
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }

            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else { fatalError("Failed to prepare for \(showWebViewIdentifier)") }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    
}

// MARK: - Делегат WebViewViewController
extension AuthViewController: WebViewViewControllerDelegate {
    
    /*
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            print("📥 Code received from WebView: \(code)")

            self.oauth2Service.fetchOAuthToken(code: code) { result in
                switch result {
                case .success(let token):
                    print("✅ Token received: \(token)")
                    print("✅ Вызван delegate?.authViewController")
                    self.delegate?.authViewController(self, didAuthenticateWithCode: code)
                case .failure(let error):
                    print("❌ Ошибка при получении токена: \(error)")
                    // Можно показать алерт или повторить попытку
                }
            }
        }
    }
     */
    
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        delegate?.authViewController(self, didAuthenticateWithCode: code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }

    
    /*
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            // Сообщаем делегату (например, SplashViewController), что авторизация успешна
            self.delegate?.authViewController(self, didAuthenticateWithCode: code)
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }
     */
}


/*
import UIKit

class AuthViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Настройка UI (например, кнопка "Войти")
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        let webViewController = WebViewViewController()
        webViewController.delegate = self
        present(webViewController, animated: true, completion: nil)
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("Received code: \(code)")
        requestAccessToken(code: code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("Authorization cancelled")
        // Здесь можно показать сообщение об отмене, если нужно
    }
    
    private func requestAccessToken(code: String) {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("Invalid token URL")
            showError("Failed to create token URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyParameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyParameters)
        } catch {
            print("Failed to serialize body: \(error)")
            showError("Failed to prepare token request")
            return
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    self?.showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    print("Invalid response: \(String(describing: response))")
                    if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                        print("Error response: \(errorResponse)")
                    }
                    self?.showError("Invalid server response")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    self?.showError("No data received from server")
                    return
                }
                
                do {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    print("Access token: \(tokenResponse.accessToken)")
                    self?.saveToken(tokenResponse.accessToken)
                    self?.showImagesList()
                } catch {
                    print("Failed to decode token response: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(jsonString)")
                    }
                    self?.showError("Failed to parse token response")
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func saveToken(_ token: String) {
        saveTokenToKeychain(token: token, forKey: "unsplashAccessToken")
        print("Token saved: \(token)")
    }
    
    private func showImagesList() {
        // Переход на стартовую страницу
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let imagesListVC = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as? ImagesListViewController {
            navigationController?.pushViewController(imagesListVC, animated: true)
        } else {
            print("Failed to instantiate ImagesListViewController")
        }
    }
}

// Структура для парсинга ответа от Unsplash
struct TokenResponse: Codable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

// Keychain для хранения токена
import Security

func saveTokenToKeychain(token: String, forKey key: String) {
    let data = token.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    print("Save status: \(status == errSecSuccess)")
}
*/
