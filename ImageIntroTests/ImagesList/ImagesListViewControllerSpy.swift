@testable import ImageIntro
import Foundation

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    private(set) var didCallInsertRows = false
    private(set) var didCallShowSingleImage = false
    private(set) var didCallShowLikeError = false
    private(set) var didCallUpdateTable = false
    
    var insertedIndexPaths: [IndexPath] = []
    var shownPhoto: Photo?
    var wasAnimated: Bool?
    
    func insertRows(at indexPaths: [IndexPath]) {
        didCallInsertRows = true
        insertedIndexPaths = indexPaths
    }
    
    func showSingleImage(_ photo: Photo) {
        didCallShowSingleImage = true
        shownPhoto = photo
    }
    
    func showLikeError() {
        didCallShowLikeError = true
    }
    
    func updateTable(animated: Bool) {
        didCallUpdateTable = true
        wasAnimated = animated
    }
}
