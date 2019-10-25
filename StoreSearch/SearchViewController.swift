import UIKit

class SearchViewController: UIViewController {
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var segmentedControl: UISegmentedControl!
	
  struct TableViewCellIdentifiers {
    static let searchResultCell = "SearchResultCell"
    static let nothingFoundCell = "NothingFoundCell"
    static let loadingCell = "LoadingCell"
  }
  
  private let search = Search()
  var landscapeVC: LandscapeViewController?
  weak var splitViewDetail: DetailViewController?
  
	override func viewDidLoad() {
    super.viewDidLoad()
    title = NSLocalizedString("Search", comment: "split view master button")
    tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
    // Register table view cells
    var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
    cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
    cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
    tableView.rowHeight = 80
    // Show keyboard
    if UIDevice.current.userInterfaceIdiom != .pad {
      searchBar.becomeFirstResponder()
    }
	}

  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    
    let rect = UIScreen.main.bounds
    if (rect.width == 736 && rect.height == 414) || (rect.width == 414 && rect.height == 736) {
      if presentedViewController != nil {
        dismiss(animated: true, completion: nil)
      }
    } else if UIDevice.current.userInterfaceIdiom != .pad {
      switch newCollection.verticalSizeClass {
      case .compact:
        showLandscape(with: coordinator)
      case .regular, .unspecified:
        hideLandscape(with: coordinator)
      }
    }
  }
  
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowDetail" {
      if case .results(let list) = search.state {
        let detailViewController = segue.destination as! DetailViewController
        let indexPath = sender as! IndexPath
        let searchResult = list[indexPath.row]
        detailViewController.searchResult = searchResult
        detailViewController.isPopUp = true
      }
    }
  }
  
  // MARK:- Actions
	@IBAction func segmentChanged(_ sender: UISegmentedControl) {
    performSearch()
	}
	
	// MARK:- Private Methods
  func showNetworkError() {
    let alert = UIAlertController(title: NSLocalizedString("Whoops...", comment:"Network error alert title"), message: NSLocalizedString("There was an error accessing the iTunes Store. Please try again.", comment:"Network error alert message"), preferredStyle: .alert)
    let action = UIAlertAction(title: NSLocalizedString("OK", comment:"OK button title"), style: .default, handler: nil)
    alert.addAction(action)
    present(alert, animated: true, completion: nil)
  }
  
  func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    guard landscapeVC == nil else { return }
    landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
    if let controller = landscapeVC {
      controller.search = search
      controller.view.frame = view.bounds
      controller.view.alpha = 0
      view.addSubview(controller.view)
      addChild(controller)
      coordinator.animate(alongsideTransition: { _ in
        controller.view.alpha = 1
        self.searchBar.resignFirstResponder()
        if self.presentedViewController != nil {
          self.dismiss(animated: true, completion: nil)
        }
      }, completion: { _ in
        controller.didMove(toParent: self)
      })
    }
  }
  
  func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
    if let controller = landscapeVC {
      controller.willMove(toParent: nil)
      coordinator.animate(alongsideTransition: { _ in
        controller.view.alpha = 0
        if self.presentedViewController != nil {
          self.dismiss(animated: true, completion: nil)
        }
      }, completion: { _ in
        controller.view.removeFromSuperview()
        controller.removeFromParent()
        self.landscapeVC = nil
      })
    }
  }
  
  private func hideMasterPane() {
    UIView.animate(withDuration: 0.25, animations: {
      self.splitViewController!.preferredDisplayMode = .primaryHidden
    }, completion: { _ in
      self.splitViewController!.preferredDisplayMode = .automatic
    })
  }
}

extension SearchViewController: UISearchBarDelegate {
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    performSearch()
  }
  
  func performSearch() {
    if let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) {
      search.performSearch(for: searchBar.text!, category: category, completion:{success in
        if !success {
          self.showNetworkError()
        }
        self.tableView.reloadData()
        self.landscapeVC?.searchResultsReceived()
      })
      tableView.reloadData()
      searchBar.resignFirstResponder()
    }
  }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch search.state {
    case .notSearchedYet:
      return 0
    case .loading:
      return 1
    case .noResults:
      return 1
    case .results(let list):
      return list.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch search.state {
    case .notSearchedYet:
      fatalError("Should never get here")
      
    case .loading:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: TableViewCellIdentifiers.loadingCell,
        for: indexPath)
      
      let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
      spinner.startAnimating()
      return cell
      
    case .noResults:
      return tableView.dequeueReusableCell(
        withIdentifier: TableViewCellIdentifiers.nothingFoundCell,
        for: indexPath)
      
    case .results(let list):
      let cell = tableView.dequeueReusableCell(
        withIdentifier: TableViewCellIdentifiers.searchResultCell,
        for: indexPath) as! SearchResultCell
      
      let searchResult = list[indexPath.row]
      cell.configure(for: searchResult)
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    searchBar.resignFirstResponder()
    if view.window!.rootViewController!.traitCollection.horizontalSizeClass == .compact {
      tableView.deselectRow(at: indexPath, animated: true)
      performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    } else {
      if case .results(let list) = search.state {
        splitViewDetail?.searchResult = list[indexPath.row]
      }
      if splitViewController!.displayMode != .allVisible {
        hideMasterPane()
      }
    }
  }
  
  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    switch search.state {
    case .notSearchedYet, .loading, .noResults:
      return nil
    case .results:
      return indexPath
    }
  }
}
