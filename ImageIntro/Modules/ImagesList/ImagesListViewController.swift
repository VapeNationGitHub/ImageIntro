import UIKit
import Kingfisher

// MARK: - Контроллер экрана со списком изображений
final class ImagesListViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Приватные свойства
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    /// Форматтер для преобразования даты загрузки фотографии
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
        tableView.accessibilityIdentifier = "images_table"
        presenter.viewDidLoad()
        
        // Подписка на уведомление о загрузке новых фото
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(imagesListDidChange(_:)),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
    }
    
    // MARK: - Уведомления
    /// Оьновление таблицы при загрузке
    @objc private func imagesListDidChange(_ notification: Notification) {
        presenter?.didChangeNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Навигация
    /// Подготовка к переходу на экран с одниночным изображением
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
    
    // MARK: - Вспомогательные методы
    /// Форматирование даты для отображения под фото
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
        
        // Установка иконки лайка
        let likeImage = photo.isLiked
        ? UIImage(resource: .likeButtonOn)
        : UIImage(resource: .likeButtonOff)
        imageListCell.likeButton.setImage(likeImage, for: .normal)
        imageListCell.likeButton.accessibilityIdentifier = photo.isLiked ? "likeButtonOn" : "likeButtonOff"
        imageListCell.configureLikeButton(isLiked: photo.isLiked)
        
        return imageListCell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    
    /// Открытие экрана с изображением при тапе по ячейке
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.didSelectPhoto(at: indexPath)
    }
    
    /// Динамический расчет высоты ячейки по пропорциям изображения
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = presenter.photo(at: indexPath)
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = imageViewWidth / photo.size.width
        return photo.size.height * scale + imageInsets.top + imageInsets.bottom
    }
    
    /// Подгрузка следующей страницы
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.willDisplayCell(at: indexPath)
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    
    /// Обработка нажатия на кнопку лайка
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            print("❌ Не удалось определить indexPath ячейки")
            return
        }
        
        // Показ спиннера в кнопке
        cell.setLikeButtonLoading(true)
        
        presenter.didTapLike(at: indexPath) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                // Скрытие спиннера
                cell.setLikeButtonLoading(false)
                
                switch result {
                case .success(let updatedPhoto):
                    // Обновление инконки лайка
                    let likeImage = updatedPhoto.isLiked
                    ? UIImage(resource: .likeButtonOn)
                    : UIImage(resource: .likeButtonOff)
                    cell.likeButton.setImage(likeImage, for: .normal)
                    cell.likeButton.accessibilityIdentifier = updatedPhoto.isLiked ? "likeButtonOn" : "likeButtonOff"
                    
                case .failure:
                    self.showLikeError()
                }
            }
        }
    }
}

// MARK: - ImagesListViewControllerProtocol
extension ImagesListViewController: ImagesListViewControllerProtocol {
    
    /// Анимированная вставка новых ячеек
    func insertRows(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.performBatchUpdates({
                self.tableView.insertRows(at: indexPaths, with: .automatic)
            })
        }
    }
    
    /// Открытие экрана с одним изображением
    func showSingleImage(_ photo: Photo) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: photo)
    }
    
    /// Показ ошибки при неудачном лайке
    func showLikeError() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось поставить лайк. Повторите позже.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    /// Перезагрузка таблицы
    func updateTable(animated: Bool) {
        if animated {
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
}
