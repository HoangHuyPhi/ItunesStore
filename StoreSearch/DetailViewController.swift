import UIKit
import MessageUI

class DetailViewController: UIViewController {
  @IBOutlet weak var popupView: UIView!
  @IBOutlet weak var artworkImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var artistNameLabel: UILabel!
  @IBOutlet weak var kindLabel: UILabel!
  @IBOutlet weak var genreLabel: UILabel!
  @IBOutlet weak var priceButton: UIButton!
  
  enum AnimationStyle {
    case slide
    case fade
  }
  
  var downloadTask: URLSessionDownloadTask?
  var dismissStyle = AnimationStyle.fade
  var isPopUp = false
  
  var searchResult: SearchResult! {
    didSet {
      if isViewLoaded {
        updateUI()
      }
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    modalPresentationStyle = .custom
    transitioningDelegate = self
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
    popupView.layer.cornerRadius = 10
    if isPopUp {
      let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
      gestureRecognizer.cancelsTouchesInView = false
      gestureRecognizer.delegate = self
      view.addGestureRecognizer(gestureRecognizer)
      
      view.backgroundColor = UIColor.clear
    } else {
      view.backgroundColor = UIColor(patternImage:UIImage(named: "LandscapeBackground")!)
      popupView.isHidden = true
      if let displayName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
        title = displayName
      }
    }
    if searchResult != nil {
      updateUI()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  deinit {
    print("deinit \(self)")
    downloadTask?.cancel()
  }
  
  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowMenu" {
      let controller = segue.destination as! MenuViewController
      controller.delegate = self
    }
  }
  
  // MARK:- Actions
  @IBAction func close() {
    dismissStyle = .slide
    dismiss(animated: true, completion: nil)
  }

  @IBAction func openInStore() {
    if let url = URL(string: searchResult.storeURL) {
      UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
  }
  
  // MARK:- Helper Methods
  func updateUI() {
    nameLabel.text = searchResult.name
    
    if searchResult.artistName.isEmpty {
      artistNameLabel.text = NSLocalizedString("Unknown", comment:"Artist Name Label")
    } else {
      artistNameLabel.text = searchResult.artistName
    }
    
    kindLabel.text = searchResult.type
    genreLabel.text = searchResult.genre
    // Show price
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = searchResult.currency
    let priceText: String
    if searchResult.price == 0 {
      priceText = NSLocalizedString("Free", comment: "Price text") 
    } else if let text = formatter.string(from: searchResult.price as NSNumber) {
      priceText = text
    } else {
      priceText = ""
    }
    priceButton.setTitle(priceText, for: .normal)
    // Get image
    if let largeURL = URL(string: searchResult.imageLarge) {
      downloadTask = artworkImageView.loadImage(url: largeURL)
    }
    popupView.isHidden = false
  }
}

extension DetailViewController: UIViewControllerTransitioningDelegate {
  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
      return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
  }
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
      return BounceAnimationController()
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    switch dismissStyle {
    case .slide:
      return SlideOutAnimationController()
    case .fade:
      return FadeOutAnimationController()
    }
  }
}

extension DetailViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return (touch.view === self.view)
  }
}

extension DetailViewController: MenuViewControllerDelegate {
  func menuViewControllerSendEmail(_: MenuViewController) {
    dismiss(animated: true) {
      if MFMailComposeViewController.canSendMail() {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        controller.modalPresentationStyle = .formSheet
        controller.setSubject(NSLocalizedString("Support Request", comment: "Email subject"))
        controller.setToRecipients(["your@email-address-here.com"])
        self.present(controller, animated: true, completion: nil)
      }
    }
  }
}

extension DetailViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    dismiss(animated: true, completion: nil)
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
