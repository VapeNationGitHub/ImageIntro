import Foundation

// MARK: - Ошибки сети
enum NetworkError: Error {
    case invalidRequest
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case decodingError(Error)
}

// MARK: - Ошибка авторизации
enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = KeychainTokenStorage.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread, "fetchOAuthToken должен вызываться из главного потока")
        
        if let task = task {
            if lastCode == code {
                print("[OAuth2Service]: Повторный запрос с тем же кодом — задача уже выполняется")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            } else {
                print("[OAuth2Service]: Отмена предыдущего запроса с другим кодом")
                task.cancel()
            }
        } else if lastCode == code {
            print("[OAuth2Service]: Повторный запрос с тем же кодом")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service]: Ошибка — не удалось создать URLRequest")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            self.task = nil
            self.lastCode = nil
            
            switch result {
            case .success(let body):
                let token = body.accessToken
                self.tokenStorage.token = token
                print("[OAuth2Service]: ✅ Токен успешно получен: \(token.prefix(10))...")
                completion(.success(token))
                
            case .failure(let error):
                print("[OAuth2Service]: ❌ Ошибка получения токена — \(error)")
                completion(.failure(error))
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Приватный метод, формируем POST-запрос для получения токена
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("🚨 Неверный URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let parameters = [
            "client_id": Constants.AccessKey,
            "client_secret": Constants.SecretKey,
            "redirect_uri": Constants.RedirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}
