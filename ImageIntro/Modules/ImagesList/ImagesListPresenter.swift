import Foundation

// MARK: - Презентер экрана со списком изображений
final class ImagesListPresenter: ImagesListPresenterProtocol {
    
    // MARK: - Свойства
    weak var view: ImagesListViewControllerProtocol?
    
    private var imagesListService: ImagesListServiceProtocol
    private var lastKnownCount: Int = 0
    
    // MARK: - Инициализация
    init(imagesListService: ImagesListServiceProtocol = ImagesListService.shared) {
        self.imagesListService = imagesListService
        self.lastKnownCount = imagesListService.photos.count
    }
    
    // MARK: - Жизненный цикл
    func viewDidLoad() {
        imagesListService.fetchPhotosNextPage()
    }
    
    // MARK: - Обновление данных
    func didChangeNotification() {
        
        let newCount = imagesListService.photos.count
        let oldCount = lastKnownCount
        
        guard newCount >= oldCount else {
            lastKnownCount = newCount
            view?.updateTable(animated: false)
            return
        }
        
        let added = newCount - oldCount
        guard added > 0 else { return }
        
        lastKnownCount = newCount
        
        let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        view?.insertRows(at: indexPaths)
        
    }
    
    // MARK: - Взаимодействие с ячейками
    func didTapCell(at indexPath: IndexPath) {
        let photo = imagesListService.photos[indexPath.row]
        view?.showSingleImage(photo)
    }
    
    func didSelectPhoto(at indexPath: IndexPath) {
        let photo = imagesListService.photos[indexPath.row]
        view?.showSingleImage(photo)
    }
    
    func willDisplayCell(at indexPath: IndexPath) {
        if indexPath.row == imagesListService.photos.count - 1 {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    // MARK: - Лайки
    func didTapLike(at indexPath: IndexPath, completion: @escaping (Result<Photo, Error>) -> Void) {
        let photo = imagesListService.photos[indexPath.row]
        let isLike = !photo.isLiked
        
        imagesListService.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            switch result {
            case .success:
                let updatedPhoto = self?.imagesListService.photos[indexPath.row]
                if let updatedPhoto = updatedPhoto {
                    completion(.success(updatedPhoto))
                }
            case .failure(let error):
                self?.view?.showLikeError()
                completion(.failure(error))
            }
        }
    }
    
    func changeLike(at indexPath: IndexPath) {
        let photo = imagesListService.photos[indexPath.row]
        let isLike = !photo.isLiked
        
        imagesListService.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            switch result {
            case .success:
                break
            case .failure:
                self?.view?.showLikeError()
            }
        }
    }
    
    // MARK: - Получение данных
    
    /// Количество фотографий в ленте
    var photosCount: Int {
        return imagesListService.photos.count
    }
    
    /// Получение фотографии по indexPath
    func photo(at indexPath: IndexPath) -> Photo {
        return imagesListService.photos[indexPath.row]
    }
}
