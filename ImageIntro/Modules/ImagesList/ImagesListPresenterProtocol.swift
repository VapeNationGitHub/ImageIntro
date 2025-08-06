import Foundation

// MARK: - Протокол View
protocol ImagesListViewProtocol: AnyObject {
    func insertRows(at indexPaths: [IndexPath])
    func reloadRow(at indexPath: IndexPath)
    func showLikeError()
}

// MARK: - Протокол Презентера
protocol ImagesListPresenterProtocol {
    var view: ImagesListViewProtocol? { get set }
    var photosCount: Int { get }
    func viewDidLoad()
    func photo(at indexPath: IndexPath) -> Photo
    func didTapLike(at indexPath: IndexPath)
    func shouldFetchNextPage(for indexPath: IndexPath)
}

