import Foundation

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photosCount: Int { get }
    func photo(at indexPath: IndexPath) -> Photo
    func viewDidLoad()
    func didSelectPhoto(at indexPath: IndexPath)
    func willDisplayCell(at indexPath: IndexPath)
    func didTapLike(at indexPath: IndexPath, completion: @escaping (Result<Photo, Error>) -> Void)
    func didChangeNotification()
}
