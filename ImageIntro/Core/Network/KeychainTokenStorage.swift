import Foundation
import SwiftKeychainWrapper

final class KeychainTokenStorage {
    static let shared = KeychainTokenStorage()
    private init() {}

    private let tokenKey = "bearerToken"

    var token: String? {
        get {
            KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let token = newValue {
                KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
}

