import Foundation

// MARK: - Сервис получения профиля пользователя
final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private var task: URLSessionTask?
    private var lastToken: String?
    private(set) var profile: Profile? // ✅ Добавлено: сохраняем результат и делаем доступным только на чтение

    // MARK: - Метод получения профиля пользователя
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)

        // ✅ Упростили проверку гонки
        guard lastToken != token else {
            completion(.failure(ProfileServiceError.requestAlreadyInProgress))
            return
        }

        task?.cancel()
        lastToken = token

        guard let request = makeRequest(token: token) else {
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }

        let session = URLSession.shared
        task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.task = nil
                self.lastToken = nil

                if let error = error {
                    print("🚨 Ошибка при выполнении запроса профиля: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data else {
                    print("🚨 Нет данных в ответе профиля")
                    completion(.failure(ProfileServiceError.emptyResponse))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let profileResult = try decoder.decode(ProfileResult.self, from: data)

                    let name = [profileResult.firstName, profileResult.lastName].compactMap { $0 }.joined(separator: " ")
                    let loginName = "@\(profileResult.username)"
                    let profile = Profile(
                        username: profileResult.username,
                        name: name,
                        loginName: loginName,
                        bio: profileResult.bio
                    )

                    self.profile = profile // ✅ Сохранили результат
                    completion(.success(profile))
                } catch {
                    print("🚨 Ошибка декодирования профиля: \(error)")
                    completion(.failure(error))
                }
            }
        }

        task?.resume()
    }

    // MARK: - Вспомогательный метод создания авторизованного GET-запроса
    private func makeRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("🚨 Неверный URL для запроса профиля")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

// MARK: - Ошибки ProfileService
enum ProfileServiceError: Error {
    case invalidRequest
    case requestAlreadyInProgress
    case emptyResponse
}

// MARK: - Структура ответа от сервера Unsplash (для декодирования JSON)
struct ProfileResult: Decodable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// MARK: - Структура, используемая в UI-слое (профиль пользователя)
struct Profile {
    let username: String          // Логин как есть
    let name: String              // Имя + фамилия
    let loginName: String         // @username
    let bio: String?              // Биография (может отсутствовать)
}
