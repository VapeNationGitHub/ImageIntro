import UIKit

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    private var photos: [Photo] = []
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        
        ImagesListService.shared.fetchPhotosNextPage()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = ImagesListService.shared.photos
        let newCount = newPhotos.count
        
        guard newCount > oldCount else { return }
        
        let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        self.photos = newPhotos
        
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
        print("updateTableViewAnimated, количество фотографий: \(photos.count)")
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            let photo = photos[indexPath.row]
            viewController.fullImageURL = URL(string: photo.largeImageURL)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            ImagesListService.shared.fetchPhotosNextPage()
        }
    }
    
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        let photo = photos[indexPath.row]
        
        imageListCell.delegate = self
        
        imageListCell.dateLabel.text = formattedDate(photo.createdAt)
        
        let placeholderImage = UIImage(named: "Stub")
        
        imageListCell.setImageState(.loading)
        
        let imageURL = URL(string: photo.thumbImageURL)
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

extension ImagesListViewController {
    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = photo.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = photo.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
}

// MARK: - Обработка нажатия кнопки лайка
extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            print("❌ Не удалось получить indexPath для ячейки")
            return
        }
        
        let photo = photos[indexPath.row]
        let isLike = !photo.isLiked
        
        // Лог
        print("❤️ Пользователь \(isLike ? "ставит" : "снимает") лайк для фото \(photo.id)")
        
        cell.setLikeButtonLoading(true)
        
        ImagesListService.shared.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            DispatchQueue.main.async {
                
                guard let self else { return }
                
                switch result {
                case .success:
                    
                    self.photos = ImagesListService.shared.photos
                    let updatedPhoto = self.photos[indexPath.row]
                    let likeImage = updatedPhoto.isLiked
                    ? UIImage(named: "like_button_on")
                    : UIImage(named: "like_button_off")
                    cell.likeButton.setImage(likeImage, for: .normal)
                    
                    cell.setLikeButtonLoading(false)
                    
                case .failure(let error):
                    
                    cell.setLikeButtonLoading(false)
                    print("❌ Ошибка при лайке: \(error)")
                    
                    let alert = UIAlertController(
                        title: "Ошибка",
                        message: "Не удалось поставить лайк. Повторите позже.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "ОК", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
