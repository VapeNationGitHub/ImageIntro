import UIKit
import ProgressHUD

// MARK: - Класс для показа индикатора с блокировкой UI
final class UIBlockingProgressHUD {
    
    // MARK: - Окно приложения
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    // MARK: - Показывает индикатор и блокирует UI
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    // MARK: - Скрывает индикатор и разблокирует UI
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
