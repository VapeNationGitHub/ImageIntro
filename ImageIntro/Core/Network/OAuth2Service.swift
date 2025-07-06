import Foundation

// MARK: - Ошибки сети
enum NetworkError: Error {
    case invalidRequest
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

// MARK: - Ошибка авторизации
enum AuthServiceError: Error {
    case invalidRequest
}

final class OAuth2Service {
    
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread, "fetchOAuthToken должен вызываться из главного потока")
        
        // Защита от повторных запросов
        if let task = task {
            if lastCode == code {
                print("Запрос уже выполняется с тками же code.")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            } else {
                print("Отмена предыдущего запроса с другим code.")
                task.cancel()
            }
        } else {
            if lastCode == code {
                print("Повторный запрос с таким же code.")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        }
        
        lastCode = code
        
        // Формируем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("Невозможно создать URLRequest")
            completion(.failure(NetworkError.invalidRequest))
            return
            
            /*
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
             */
        }
        
        
        
        
        
        
        
        // Отправляем запрос
        
        
        task = URLSession.shared.data(for: request) {[weak self] result in
            guard let self else { return}
            self.task = nil
            self.lastCode = nil
            
            switch result {
                case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
                    self.tokenStorage.token = token
                    print("Токен получен и сохранен: \(token.prefix(10))...")
                    completion(.success(token))
                } catch {
                    print("Ошибка декодирования токена: \(error)")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                print("Ошибка сетевого запроса \(error)")
                completion(.failure(error))
            }
        }
        
        /*
        let session = URLSession.shared
        task = session.data(for: request) { [weak self] result in
            guard let self = self else { return }
            self.task = nil
            
            switch result {
            case .success(let data):
                do {
                    // Декодируем JSON-ответ
                    let decoder = JSONDecoder()
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
                    
                    // Сохраняем и возвращаем токен
                    self.tokenStorage.token = token
                    completion(.success(token))
                } catch {
                    print("🚨 Ошибка декодирования: \(error)")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                print("🚨 Ошибка при выполнении запроса токена: \(error)")
                completion(.failure(error))
            }
        }
         */
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
