import Foundation

protocol ImagesListViewControllerProtocol: AnyObject {
    func insertRows(at indexPaths: [IndexPath])
    func showSingleImage(_ photo: Photo)
    func showLikeError()
    func updateTable(animated: Bool)
}
