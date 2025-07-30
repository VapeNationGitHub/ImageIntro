import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}

    func logout() {
        cleanCookies()
        cleanToken()
        cleanServices()
    }

    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: {})
        }
    }

    private func cleanToken() {
        KeychainTokenStorage.shared.removeToken()
    }

    private func cleanServices() {
        ProfileService.shared.reset()
        ProfileImageService.shared.reset()
        ImagesListService.shared.reset()
    }
}

