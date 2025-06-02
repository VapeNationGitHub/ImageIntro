import Foundation

// MARK: - Сервис получения OAuth-токена Unsplash
final class OAuth2Service {

    // Singleton
    static let shared = OAuth2Service()
    private init() {}

    // Хранилище токена
    private let tokenStorage = OAuth2TokenStorage.shared

    // Текущая задача (чтобы не создавать дубликаты запросов)
    private var task: URLSessionTask?

    // MARK: – Публичный метод
    /// Получает Bearer-токен по коду авторизации
    /// - Parameters:
    ///   - code: код, который вернул Unsplash после авторизации
    ///   - completion: completion(Result<String,Error>) – всегда вызывается на **главном** потоке
    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Не отправляем второй запрос, если уже есть незавершённая задача
        guard task == nil else { return }

        // Собираем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }

        task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self else { return }
            self.task = nil

            switch result {
            case .success(let data):
                do {
                    // Декодируем JSON-ответ
                    let body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
                    // Сохраняем токен
                    self.tokenStorage.token = token

                    // ✅ Успех – вызываем completion НА ГЛАВНОМ ПОТОКЕ
                    DispatchQueue.main.async {
                        completion(.success(token))
                    }

                } catch {
                    print("🚨 Ошибка декодирования: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                print("🚨 Сетевая ошибка при запросе токена: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task?.resume()
    }
}

// MARK: - Приватные вспомогательные методы
private extension OAuth2Service {

    /// Формирует URLRequest для POST-запроса токена
    func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("🚨 Неверный URL для запроса токена")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Параметры формы (x-www-form-urlencoded)
        let parameters: [String: String] = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]

        let bodyString = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "Content-Type")

        return request
    }
}

// MARK: - Ошибки сети
enum NetworkError: Error {
    case invalidRequest
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}



/*
import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    private let tokenStorage = OAuth2TokenStorage.shared

    private var task: URLSessionTask?

    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard task == nil else { return }

        var request = makeOAuthTokenRequest(code: code)
        guard let request = request else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let session = URLSession.shared
        task = session.data(for: request) { [weak self] result in
            guard let self = self else { return }
            self.task = nil

            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
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

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("🚨 Неверный URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let parameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
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

enum NetworkError: Error {
    case invalidRequest
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}
*/
