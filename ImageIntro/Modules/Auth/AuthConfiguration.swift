import Foundation

enum Constants {
    static let AccessKey = "uPB0L8MgssoSQer-oVMyykFJI7_G-JE8LrO19QY1O4U"
    static let SecretKey = "ti-b7fBml78hZFJMf1QCGDEiQe5ftDB7cHY0sSd6pf0"
    static let RedirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let AccessScope = "public+read_user+write_likes"
    static let DefaultBaseURL = URL(string: "https://api.unsplash.com")!
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
            accessKey: Constants.AccessKey,
            secretKey: Constants.SecretKey,
            redirectURI: Constants.RedirectURI,
            accessScope: Constants.AccessScope,
            authURLString: Constants.unsplashAuthorizeURLString,
            defaultBaseURL: Constants.DefaultBaseURL
        )
    }
}
