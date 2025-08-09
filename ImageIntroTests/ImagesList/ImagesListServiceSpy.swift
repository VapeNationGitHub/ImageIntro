@testable import ImageIntro
import Foundation

final class ImagesListServiceSpy: ImagesListServiceProtocol {
    var photos: [Photo] = []
    private(set) var didCallFetchPhotosNextPage = false
    private(set) var didCallChangeLike = false
    var expectedChangeLikeResult: Result<Void, Error>?
    
    func fetchPhotosNextPage() {
        didCallFetchPhotosNextPage = true
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        didCallChangeLike = true
        if let result = expectedChangeLikeResult {
            completion(result)
        }
    }
}
