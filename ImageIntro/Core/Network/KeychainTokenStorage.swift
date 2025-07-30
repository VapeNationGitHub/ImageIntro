import Foundation
import SwiftKeychainWrapper

final class KeychainTokenStorage {
    static let shared = KeychainTokenStorage()
    private init() {}
    
    private let tokenKey = "bearerToken"
    
    var token: String? {
        get {
            let token = KeychainWrapper.standard.string(forKey: tokenKey)
            print("🧪 [Keychain] Проверка токена: \(token?.prefix(10) ?? "nil")")
            return token
        }
        set {
            if let token = newValue {
                print("💾 [Keychain] Сохраняем токен: \(token.prefix(10))...")
                KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                print("🧹 [Keychain] Удаляем токен")
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
    
    func removeToken() {
        token = nil
    }

}

