import Foundation

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    
    private var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared
    
    func viewDidLoad() {
        imagesListService.fetchPhotosNextPage()
        
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let oldCount = self.photos.count
            self.photos = self.imagesListService.photos
            let newCount = self.photos.count
            if newCount > oldCount {
                let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                view?.insertRows(at: indexPaths)
            }
        }
    }
    
    var photosCount: Int {
        return photos.count
    }
    
    func photo(at indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }
    
    func willDisplayCell(at indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func didSelectPhoto(at indexPath: IndexPath) {
        view?.showSingleImage(photo(at: indexPath))
    }
    
    func didTapLike(at indexPath: IndexPath, completion: @escaping (Result<Photo, Error>) -> Void) {
        let photo = photos[indexPath.row]
        let isLike = !photo.isLiked
        imagesListService.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.photos = imagesListService.photos
                completion(.success(self.photos[indexPath.row]))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
