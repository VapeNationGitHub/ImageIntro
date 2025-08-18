import Foundation

enum Constants {
    static let accessKey = "uPB0L8MgssoSQer-oVMyykFJI7_G-JE8LrO19QY1O4U"
    static let secretKey = "ti-b7fBml78hZFJMf1QCGDEiQe5ftDB7cHY0sSd6pf0"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURL = URL(string: "https://api.unsplash.com")!
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

// MARK: - Конфигурация авторизации
struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let authURLString: String
    let defaultBaseURL: URL
    
    
    // MARK: - Стандартная конфигурация (прод)
    static var standard: AuthConfiguration {
        return AuthConfiguration(
            accessKey: Constants.accessKey,
            secretKey: Constants.secretKey,
            redirectURI: Constants.redirectURI,
            accessScope: Constants.accessScope,
            authURLString: Constants.unsplashAuthorizeURLString,
            defaultBaseURL: Constants.defaultBaseURL
        )
    }
}
