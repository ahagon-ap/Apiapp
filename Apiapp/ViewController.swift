import UIKit
import Parchment

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pagingViewController = PagingViewController(viewControllers: [
            storyboard!.instantiateViewController(identifier: "ApiViewController"),
            storyboard!.instantiateViewController(identifier: "FavoriteViewController")
        ])
        
        self.addChild(pagingViewController)
        self.view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        let pagingView: UIView = pagingViewController.view
        let safeArea = self.view.safeAreaLayoutGuide
        pagingView.translatesAutoresizingMaskIntoConstraints = false
        pagingView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        pagingView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        pagingView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
        pagingView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
    }
    
    
}

