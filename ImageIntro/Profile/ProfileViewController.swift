import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - UI
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "PhotoProfile"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds   = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text          = "Екатерина Новикова"
        label.font          = UIFont.boldSystemFont(ofSize: 23)
        label.textColor     = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.text          = "@ekaterina_nov"
        label.font          = UIFont.systemFont(ofSize: 13)
        label.textColor     = UIColor(white: 1, alpha: 0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text          = "Hello, world!"
        label.font          = UIFont.systemFont(ofSize: 13)
        label.textColor     = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let exitButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Exit"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        addSubviews()
        addConstraints()
    }
}

// MARK: - Private helpers
private extension ProfileViewController {
    
    // 1. Цвет фона и доп. настройки
    func configureAppearance() {
        view.backgroundColor = UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1) // #1A1B22
        exitButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }
    
    @objc func didTapLogout() {
        tabBarController?.selectedIndex = 0
    }
    
    // 2. Иерархия
    func addSubviews() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(messageLabel)
        view.addSubview(exitButton)
    }
    
    // 3. Auto Layout
    func addConstraints() {
        let safe = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            
            // Фотография профиля пользователя
            profileImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 32),
            profileImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            
            // Кнопка выхода
            exitButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            exitButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            exitButton.widthAnchor.constraint(equalToConstant: 24),
            exitButton.heightAnchor.constraint(equalTo: exitButton.widthAnchor),
            
            // ФИО
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: exitButton.leadingAnchor, constant: -8),
            
            // Логин
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16),
            
            // Сообщение "Hello, world"
            messageLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16)
        ])
    }
}
