import UIKit

final class ImagesListCell: UITableViewCell {
    
    weak var delegate: ImagesListCellDelegate?
    
    static let reuseIdentifier = "ImagesListCell"
    
    // Хранилище слоёв
    private var animationLayers = Set<CALayer>()
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet weak var likeButtonActivityIndicator: UIActivityIndicatorView!
    
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
        likeButton.isHidden = isLoading
        if isLoading {
            likeButtonActivityIndicator.startAnimating()
        } else {
            likeButtonActivityIndicator.stopAnimating()
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
