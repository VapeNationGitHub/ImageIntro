import Foundation

// MARK: - Ошибки сети
enum NetworkError: Error {
    case invalidRequest
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private let tokenStorage = OAuth2TokenStorage.shared
    
    private var task: URLSessionTask?
    
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard task == nil else { return }
        
        // Формируем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }
        
        // Отправляем запрос
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
