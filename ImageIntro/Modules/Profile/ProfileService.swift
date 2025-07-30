import Foundation

// MARK: - Сервис получения профиля пользователя
final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private var task: URLSessionTask?
    private var lastToken: String?
    private(set) var profile: Profile?
    
    // MARK: - Метод получения профиля пользователя
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Защита от повторных запросов с тем же токеном
        guard lastToken != token else {
            print("[ProfileService]: Ошибка — повторный запрос уже выполняется с token: \(token.prefix(10))...")
            completion(.failure(ProfileServiceError.requestAlreadyInProgress))
            return
        }
        
        task?.cancel()
        lastToken = token
        
        guard let request = makeRequest(token: token) else {
            print("[ProfileService]: Ошибка — невозможно сформировать URLRequest для token: \(token.prefix(10))...")
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self = self else { return }
            self.task = nil
            self.lastToken = nil
            
            switch result {
            case .success(let profileResult):
                let name = [profileResult.firstName, profileResult.lastName].compactMap { $0 }.joined(separator: " ")
                let loginName = "@\(profileResult.username)"
                let profile = Profile(
                    username: profileResult.username,
                    name: name,
                    loginName: loginName,
                    bio: profileResult.bio
                )
                self.profile = profile
                completion(.success(profile))
                
            case .failure(let error):
                print("[ProfileService][fetchProfile]: Ошибка — \(error.localizedDescription), token: \(token.prefix(10))...")
                completion(.failure(error))
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Вспомогательный метод создания авторизованного GET-запроса
    private func makeRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            print("[ProfileService]: Ошибка — некорректный URL при создании запроса")
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
