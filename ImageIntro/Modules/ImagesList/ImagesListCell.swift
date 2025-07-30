import UIKit

final class ImagesListCell: UITableViewCell {
    
    weak var delegate: ImagesListCellDelegate?
    
    static let reuseIdentifier = "ImagesListCell"
    
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
}

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}
