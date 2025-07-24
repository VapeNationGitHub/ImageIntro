import Foundation

// MARK: - Сервис загрузки URL аватарки пользователя
final class ProfileImageService {
    
    // MARK: - Singleton
    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageServiceDidChangeNotification")
    private init() {}
    
    // MARK: - Свойства
    private var task: URLSessionTask?
    private var lastUsername: String?
    private(set) var avatarURL: String?
    
    // MARK: - Метод получения URL маленькой аватарки пользователя
    func fetchProfileImageURL(
        username: String,
        _ completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)
        
        if task != nil {
            if lastUsername == username {
                print("[ProfileImageService]: Ошибка — повторный запрос уже выполняется для username: \(username)")
                completion(.failure(ProfileImageServiceError.requestAlreadyInProgress))
                return
            } else {
                print("[ProfileImageService]: Отмена предыдущего запроса с другим username")
                task?.cancel()
            }
        } else if lastUsername == username {
            print("[ProfileImageService]: Ошибка — повторный запрос уже выполнялся для username: \(username)")
            completion(.failure(ProfileImageServiceError.requestAlreadyInProgress))
            return
        }
        
        lastUsername = username
        
        guard let request = makeRequest(for: username) else {
            print("[ProfileImageService]: Ошибка — невозможно сформировать URLRequest для username: \(username)")
            completion(.failure(ProfileImageServiceError.invalidRequest))
            return
        }
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }
            self.task = nil
            self.lastUsername = nil
            
            switch result {
            case .success(let userResult):
                let profileImageURL = userResult.profileImage.small
                self.avatarURL = profileImageURL
                completion(.success(profileImageURL))
                
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": profileImageURL]
                )
                
            case .failure(let error):
                print("[ProfileImageService]: Ошибка при получении аватарки для \(username) — \(error)")
                completion(.failure(error))
            }
        }
        
        task?.resume()
    }
    
    // MARK: - Приватный метод создания запроса
    private func makeRequest(for username: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            print("[ProfileImageService]: Ошибка — некорректный URL для username: \(username)")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("[ProfileImageService]: Ошибка — отсутствует токен при получении аватарки")
            return nil
        }
        
        return request
    }
}

// MARK: - Структура для декодирования JSON-ответа
struct UserResult: Codable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let small: String
}

// MARK: - Ошибки сервиса
enum ProfileImageServiceError: Error {
    case invalidRequest
    case requestAlreadyInProgress
    case emptyResponse
}
