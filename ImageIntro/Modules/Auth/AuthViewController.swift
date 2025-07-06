import UIKit
import ProgressHUD

// MARK: - Протокол делегата AuthViewController
protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String)
}

final class AuthViewController: UIViewController {
    private let ShowWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else { fatalError("Failed to prepare for \(ShowWebViewSegueIdentifier)") }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - Делегат WebViewViewController
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        vc.dismiss(animated: true)
        ProgressHUD.animate()
        fetchOAuthToken(code) {[weak self] result in
            ProgressHUD.dismiss()
            guard let self = self else {return}
            
            switch result{
            case .success:
                self.delegate?.authViewController(self, didAuthenticateWithCode: code)
            case .failure:
                break
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        dismiss(animated: true)
    }
}

extension AuthViewController {
    private func fetchOAuthToken(_ code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        oauth2Service.fetchOAuthToken(code: code) { result in
            switch result {
            case .success:
                completion(.success(())) // просто говорим "успех", ничего не возвращаем
            case .failure(let error):
                completion(.failure(error)) // прокидываем ошибку дальше
            }
        }
    }
}

