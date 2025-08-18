import XCTest
@testable import ImageIntro


// MARK: - Мок ViewController
final class MockProfileViewController: ProfileViewControllerProtocol {
    var didCallUpdateProfileDetails = false
    var didCallUpdateAvatar = false
    var didCallShowLogoutAlert = false
    
    func updateProfileDetails(profile: Profile) {
        didCallUpdateProfileDetails = true
    }
    
    func updateAvatar(url: URL) {
        didCallUpdateAvatar = true
    }
    
    func showLogoutAlert() {
        didCallShowLogoutAlert = true
    }
}


// MARK: - Мок ProfileService
final class MockProfileService: ProfileServiceProtocol {
    var profile: Profile? = Profile(username: "test_user", name: "Test User", loginName: "@test", bio: "Just a test bio")
}


// MARK: - Мок ProfileImageService
final class MockProfileImageService: ProfileImageServiceProtocol {
    var avatarURL: String? = "https://example.com/avatar.png"
}


// MARK: - Тесты ProfilePresenter
final class ProfilePresenterTests: XCTestCase {
    
    // Тест - вызов методов обновления профиля и аватарки при viewDidLoad()
    func testViewDidLoadCallsUpdateMethods() {
        // given
        let view = MockProfileViewController()
        let profileService = MockProfileService()
        let profileImageService = MockProfileImageService()
        let presenter = ProfilePresenter(
            profileService: profileService,
            profileImageService: profileImageService
        )
        presenter.view = view
        
        // when
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(view.didCallUpdateProfileDetails, "Метод updateProfileDetails не был вызван")
        XCTAssertTrue(view.didCallUpdateAvatar, "Метод updateAvatar не был вызван")
    }
    
    // Тест - показ алерта выхода при нажатии кнопки "выйти"
    func testDidTapLogoutCallsShowLogoutAlert() {
        // given
        let view = MockProfileViewController()
        let presenter = ProfilePresenter(
            profileService: MockProfileService(),
            profileImageService: MockProfileImageService()
        )
        presenter.view = view

        // when
        presenter.didTapLogout()

        // then
        XCTAssertTrue(view.didCallShowLogoutAlert, "⚠️ Метод showLogoutAlert не был вызван")
    }
    
    // Тест - обновление аватарки при получении уведомления
    func testUpdateAvatarNotificationCallsUpdateAvatar() {
        // given
        let view = MockProfileViewController()
        let profileService = MockProfileService()
        let profileImageService = MockProfileImageService()
        let presenter = ProfilePresenter(
            profileService: profileService,
            profileImageService: profileImageService
        )
        presenter.view = view
        
        // when
        presenter.updateAvatarNotification()
        
        // then
        XCTAssertTrue(view.didCallUpdateAvatar, "Метод updateAvatar не был вызван из updateAvatarNotification")
    }
}
