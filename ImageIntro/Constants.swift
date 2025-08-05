import Foundation

enum Constants {
    static let AccessKey = "uPB0L8MgssoSQer-oVMyykFJI7_G-JE8LrO19QY1O4U"
    static let SecretKey = "ti-b7fBml78hZFJMf1QCGDEiQe5ftDB7cHY0sSd6pf0"
    static let RedirectURI = "urn:ietf:wg:oauth:2.0:oob"
    
    static let AccessScope = "public+read_user+write_likes"
    
    static let DefaultBaseURL: URL = {
        guard let url = URL(string: "https://api.unsplash.com") else {
            fatalError("[Constants]: Некорректный URL")
        }
        return url
    }()
}

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}
