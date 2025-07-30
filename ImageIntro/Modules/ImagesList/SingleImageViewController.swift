import  UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    var fullImageURL: URL?
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var scrollView: UIScrollView!
    
    /*
     override func viewDidLoad() {
     super.viewDidLoad()
     scrollView.minimumZoomScale = 0.1
     scrollView.maximumZoomScale = 1.25
     
     guard let fullImageURL else { return }
     
     imageView.kf.indicatorType = .activity
     imageView.kf.setImage(with: fullImageURL) { [weak self] result in
     guard let self, let resultImage = try? result.get().image else { return }
     imageView.frame.size = resultImage.size
     scrollView.contentSize = resultImage.size
     rescaleAndCenterImageInScrollView(image: resultImage)
     }
     }
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        reloadImage()
    }
    
    @IBAction private func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - Image loading
    private func reloadImage() {
        guard let fullImageURL else { return }
        
        
        /*
         UIBlockingProgressHUD.show()
         
         imageView.kf.setImage(with: fullImageURL) { [weak self] result in
         guard let self else { return }
         UIBlockingProgressHUD.dismiss()
         
         switch result {
         case .success(let imageResult):
         let image = imageResult.image
         self.imageView.frame.size = image.size
         self.scrollView.contentSize = image.size
         self.rescaleAndCenterImageInScrollView(image: image)
         case .failure:
         self.showError()
         }
         }
         */
        
        UIBlockingProgressHUD.show()
        
        imageView.kf.setImage(with: fullImageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch result {
            case .success(let imageResult):
                imageView.image = imageResult.image
                view.layoutIfNeeded()
                rescaleAndCenterImageInScrollView(image: imageResult.image)
            case .failure:
                showError()
            }
        }
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Что-то пошло не так. Попробовать ещё раз?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.reloadImage()
        })
        present(alert, animated: true)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        
        view.layoutIfNeeded()
        
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        let hScale = imageSize.width == 0 ? 0 : visibleRectSize.width / imageSize.width
        let vScale = imageSize.height == 0 ? 0 : visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

// MARK: - UIScrollViewDelegate
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
