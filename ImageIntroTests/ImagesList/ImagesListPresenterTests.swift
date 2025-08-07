import XCTest
@testable import ImageIntro

final class ImagesListPresenterTests: XCTestCase {
    
    private var presenter: ImagesListPresenter!
    private var view: ImagesListViewControllerSpy!
    private var service: ImagesListServiceSpy!
    
    override func setUp() {
        super.setUp()
        view = ImagesListViewControllerSpy()
        service = ImagesListServiceSpy()
        presenter = ImagesListPresenter(imagesListService: service)
        presenter.view = view
    }
    
    override func tearDown() {
        presenter = nil
        view = nil
        service = nil
        super.tearDown()
    }
    
    func testViewDidLoadCallsFetchPhotosNextPage() {
        // Act
        presenter.viewDidLoad()
        
        // Assert
        XCTAssertTrue(service.didCallFetchPhotosNextPage, "fetchPhotosNextPage должен быть вызван")
    }
    
    func testDidChangeNotificationInsertsRows() {
        // Arrange
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 100), createdAt: Date(), welcomeDescription: nil, thumbImageURL: "url", largeImageURL: "url", isLiked: false)
        service.photos = [photo]
        
        // Act
        presenter.didChangeNotification()
        
        // Assert
        XCTAssertTrue(view.didCallInsertRows, "Метод insertRows должен быть вызван")
        XCTAssertEqual(view.insertedIndexPaths, [IndexPath(row: 0, section: 0)], "insertRows должен вызываться с правильным индексом")
    }
    
    func testDidTapCellCallsShowSingleImage() {
        // Arrange
        let photo = Photo(id: "1", size: CGSize(width: 100, height: 100), createdAt: Date(), welcomeDescription: nil, thumbImageURL: "url", largeImageURL: "url", isLiked: false)
        service.photos = [photo]
        
        // Act
        presenter.didTapCell(at: IndexPath(row: 0, section: 0))
        
        // Assert
        XCTAssertTrue(view.didCallShowSingleImage)
        XCTAssertEqual(view.shownPhoto?.id, "1")
    }
    
    func testChangeLikeSuccess() {
        // Arrange
        let photo = Photo(id: "1", size: .zero, createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        service.photos = [photo]
        service.expectedChangeLikeResult = .success(())
        
        // Act
        presenter.changeLike(at: IndexPath(row: 0, section: 0))
        
        // Assert
        XCTAssertTrue(service.didCallChangeLike)
    }
    
    func testChangeLikeFailureShowsError() {
        // Arrange
        let photo = Photo(id: "1", size: .zero, createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
        service.photos = [photo]
        service.expectedChangeLikeResult = .failure(NSError(domain: "", code: 0))
        
        // Act
        presenter.changeLike(at: IndexPath(row: 0, section: 0))
        
        // Assert
        XCTAssertTrue(view.didCallShowLikeError)
    }
}
