import Foundation
import UIKit

final class ImagesListService {
    // MARK: - Singleton
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    private init() {}
    
    // MARK: - Свойства
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private var isLoading = false
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    // MARK: - Метод загрузки следующей страницы
    func fetchPhotosNextPage() {
        guard !isLoading else { return }
        isLoading = true
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let token = KeychainTokenStorage.shared.token else {
            assertionFailure("Token is nil")
            return
        }

        var urlComponents = URLComponents(string: "https://api.unsplash.com/photos")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(nextPage)"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            self.task = nil
            self.isLoading = false
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map(self.convertToPhoto)
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
                }
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: NetworkError - \(error)")
            }
        }
        
        task?.resume()
    }
    
    func reset() {
        photos = []
        lastLoadedPage = nil
    }
    
    // MARK: - Преобразование JSON PhotoResult в модель Photo
    private func convertToPhoto(from result: PhotoResult) -> Photo {
        let size = CGSize(width: result.width, height: result.height)
        let createdAt = dateFormatter.date(from: result.createdAt ?? "")
        return Photo(
            id: result.id,
            size: size,
            createdAt: createdAt,
            welcomeDescription: result.description,
            thumbImageURL: result.urls.thumb,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }
    
    // MARK: - Метод "установки" лайков
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        // Получаем токен из Keychain
        guard let token = KeychainTokenStorage.shared.token else {
            assertionFailure("❌ Токен отсутствует")
            completion(.failure(NetworkError.unauthorized))
            return
        }

        // Формируем URL запроса
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            assertionFailure("❌ Невалидный URL")
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Настраиваем запрос: метод POST (если лайк) или DELETE (если дизлайк)
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Отправляем сетевой запрос
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let self = self else { return }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("✅ Успешный \(isLike ? "лайк" : "дизлайк") для фото \(photoId)")

                // Обновляем массив photos на главном потоке
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: !photo.isLiked
                        )

                        self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)

                        // Отправим уведомление об изменениях
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self
                        )
                    }
                    completion(.success(()))
                }
            } else {
                print("❌ Неуспешный ответ сервера: код \(httpResponse.statusCode)")
                completion(.failure(NetworkError.httpStatus(httpResponse.statusCode)))
            }
        }

        task.resume()
    }

}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var newArray = self
        newArray[index] = newValue
        return newArray
    }
}
