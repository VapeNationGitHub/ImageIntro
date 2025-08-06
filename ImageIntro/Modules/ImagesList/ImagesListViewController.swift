import UIKit
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var tableView: UITableView!
    
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Презентер
    private var presenter: ImagesListPresenterProtocol!
    
    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        self.presenter.view = self
    }
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        presenter.viewDidLoad()
    }
    
    // MARK: - prepare(for segue:)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let photo = sender as? Photo
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            viewController.fullImageURL = URL(string: photo.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.photosCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        let photo = presenter.photo(at: indexPath)
        
        imageListCell.delegate = self
        imageListCell.dateLabel.text = formattedDate(photo.createdAt)
        imageListCell.setImageState(.loading)
        
        let imageURL = URL(string: photo.thumbImageURL)
        let placeholderImage = UIImage(named: "Stub")
        imageListCell.cellImage.kf.setImage(with: imageURL, placeholder: placeholderImage) { result in
            switch result {
            case .success(let imageResult):
                imageListCell.setImageState(.finished(imageResult.image))
            case .failure:
                imageListCell.setImageState(.error)
            }
        }
        
        let likeImage = photo.isLiked
            ? UIImage(resource: .likeButtonOn)
            : UIImage(resource: .likeButtonOff)
        imageListCell.likeButton.setImage(likeImage, for: .normal)
        
        return imageListCell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelectPhoto(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = presenter.photo(at: indexPath)
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplayCell(at: indexPath)
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            print("❌ Не удалось определить indexPath ячейки")
            return
        }
        
        cell.setLikeButtonLoading(true)
        presenter.didTapLike(at: indexPath) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                cell.setLikeButtonLoading(false)
                switch result {
                case .success(let updatedPhoto):
                    let likeImage = updatedPhoto.isLiked
                        ? UIImage(resource: .likeButtonOn)
                        : UIImage(resource: .likeButtonOff)
                    cell.likeButton.setImage(likeImage, for: .normal)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                case .failure:
                    self.showLikeError()
                }
            }
        }
    }
}

// MARK: - ImagesListViewControllerProtocol
extension ImagesListViewController: ImagesListViewControllerProtocol {
    func insertRows(at indexPaths: [IndexPath]) {
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
    
    func showSingleImage(_ photo: Photo) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: photo)
    }
    
    func showLikeError() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось поставить лайк. Повторите позже.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}
