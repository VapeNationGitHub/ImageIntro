import UIKit

final class ImagesListCell: UITableViewCell {
    
    weak var delegate: ImagesListCellDelegate?
    
    static let reuseIdentifier = "ImagesListCell"
    
    // Хранилище слоёв
    private var animationLayers = Set<CALayer>()
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet private weak var likeButtonActivityIndicator: UIActivityIndicatorView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Чтобы тесты могли дождаться окончания «крутилки»
        likeButtonActivityIndicator.accessibilityIdentifier = "likeSpinner"
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
    }
    
    // MARK: - Обработка нажатия кнопки лайка
    @IBAction private func likeButtonClicked(_ sender: UIButton) {
        delegate?.imageListCellDidTapLike(self)
    }
    
    // Метод видимости состояния индикатора
    func setLikeButtonLoading(_ isLoading: Bool) {
        if ProcessInfo.processInfo.arguments.contains("--ui-tests") {
            // В UI-тестах ничего не показываем, чтобы не перекрывать кнопку
            likeButton.isHidden = false
            likeButtonActivityIndicator.stopAnimating()
            likeButtonActivityIndicator.isHidden = true
            likeButtonActivityIndicator.isUserInteractionEnabled = false
            return
        }
        
        likeButton.isHidden = isLoading
        if isLoading {
            likeButtonActivityIndicator.isHidden = false
            likeButtonActivityIndicator.startAnimating()
        } else {
            likeButtonActivityIndicator.stopAnimating()
            likeButtonActivityIndicator.isHidden = true
        }
    }
    
    private func addSkeleton() {
        let gradient = CAGradientLayer()
        gradient.frame = cellImage.bounds
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(white: 0.85, alpha: 1).cgColor,
            UIColor(white: 0.75, alpha: 1).cgColor,
            UIColor(white: 0.85, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 16
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0, 0.1, 0.3]
        animation.toValue = [0.8, 0.9, 1]
        animation.duration = 1.0
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "skeletonAnimation")
        
        animationLayers.insert(gradient)
        cellImage.layer.addSublayer(gradient)
    }
    
    private func removeSkeletons() {
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }
    
    func setImageState(_ state: FeedCellImageState) {
        switch state {
        case .loading:
            cellImage.image = nil
            addSkeleton()
        case .finished(let image):
            removeSkeletons()
            cellImage.image = image
        case .error:
            removeSkeletons()
            cellImage.image = UIImage(named: "placeholder_error")
        }
    }
    
    // MARK: - Конфигурация лайка (иконка + id для UI-тестов)
    func configureLikeButton(isLiked: Bool) {
        let img = isLiked ? UIImage(resource: .likeButtonOn) : UIImage(resource: .likeButtonOff)
        likeButton.setImage(img, for: .normal)
        likeButton.accessibilityIdentifier = isLiked ? "likeButtonOn" : "likeButtonOff"
    }
}


protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

// Состояние загрузки
enum FeedCellImageState {
    case loading
    case finished(UIImage)
    case error
}
