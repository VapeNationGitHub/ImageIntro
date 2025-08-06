import Foundation

// MARK: - Протокол View
protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(profile: Profile)
    func updateAvatar(url: URL)
    func showLogoutAlert()
}

// MARK: - Протокол Презентера
protocol ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
    func updateAvatarNotification()
}
