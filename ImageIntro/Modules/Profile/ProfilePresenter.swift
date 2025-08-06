import Foundation

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?

    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol

    init(profileService: ProfileServiceProtocol = ProfileService.shared,
         profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared) {
        self.profileService = profileService
        self.profileImageService = profileImageService
    }

    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.updateProfileDetails(profile: profile)
        }

        if let urlString = profileImageService.avatarURL,
           let url = URL(string: urlString) {
            view?.updateAvatar(url: url)
        }
    }

    func updateAvatarNotification() {
        if let urlString = profileImageService.avatarURL,
           let url = URL(string: urlString) {
            view?.updateAvatar(url: url)
        }
    }

    func didTapLogout() {
        view?.showLogoutAlert()
    }
}
