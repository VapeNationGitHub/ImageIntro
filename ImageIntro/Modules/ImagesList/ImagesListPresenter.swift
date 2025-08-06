import Foundation

final class ImagesListPresenter: ImagesListPresenterProtocol {
    
    // MARK: - Свойства
    weak var view: ImagesListViewProtocol?
    
    private var photos: [Photo] = []
    private let imagesListService: ImagesListService
    
    init(imagesListService: ImagesListService = .shared) {
        self.imagesListService = imagesListService
    }
    
    var photosCount: Int {
        photos.count
    }
    
    // MARK: - Методы жизненного цикла
    func viewDidLoad() {
        imagesListService.fetchPhotosNextPage()
        
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.didReceivePhotosUpdate()
        }
    }
    
    private func didReceivePhotosUpdate() {
        let oldCount = photos.count
        let newPhotos = imagesListService.photos
        let newCount = newPhotos.count
        
        guard newCount > oldCount else { return }
        
        photos = newPhotos
        let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        view?.insertRows(at: indexPaths)
    }
    
    func photo(at indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }
    
    // MARK: - Обработка лайка
    func didTapLike(at indexPath: IndexPath) {
        var photo = photo(at: indexPath)
        let isLike = !photo.isLiked
        
        imagesListService.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            guard let self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.photos = self.imagesListService.photos
                    self.view?.reloadRow(at: indexPath)
                    
                case .failure(let error):
                    print("❌ Ошибка при лайке: \(error)")
                    self.view?.showLikeError()
                }
            }
        }
    }
    
    // MARK: - Проверка необходимости догрузки
    func shouldFetchNextPage(for indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

