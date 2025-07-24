import UIKit

// MARK: - Контроллер профиля пользователя
final class ProfileViewController: UIViewController {
    
    // MARK: - UI
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "PhotoProfile"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 23)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let exitButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Exit"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Жизненный цикл
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) {[weak self] _ in
            guard let self = self else {return}
            self.updateAvatar()
        }
        
        updateAvatar()
        
        configureAppearance()
        addSubviews()
        addConstraints()
        
        // Обновляем отображение данных профиля
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        } else {
            print("⚠️ Профиль не найден в ProfileService")
        }
        
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        // TODO [Sprint 11] Обновить аватар, используя Kingfisher
        
    }
    
    
    
    // MARK: - Обновление UI из профиля
    
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        loginNameLabel.text = profile.loginName
        messageLabel.text = profile.bio
    }
}

// MARK: - Private helpers

private extension ProfileViewController {
    
    func configureAppearance() {
        view.backgroundColor = UIColor(named: "YP_BlackColor")
        exitButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
    }
    
    @objc func didTapLogout() {
        tabBarController?.selectedIndex = 0
    }
    
    func addSubviews() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(messageLabel)
        view.addSubview(exitButton)
    }
    
    func addConstraints() {
        let safe = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            
            // Фото
            profileImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 32),
            profileImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            
            // Кнопка выхода
            exitButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            exitButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            exitButton.widthAnchor.constraint(equalToConstant: 44),
            exitButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Имя
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: exitButton.leadingAnchor, constant: -8),
            
            // Логин
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16),
            
            // Bio
            messageLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16)
        ])
    }
}
