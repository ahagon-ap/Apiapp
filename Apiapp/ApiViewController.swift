import UIKit
import Alamofire
import AlamofireImage
import RealmSwift
import SafariServices

class ApiViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let realm = try! Realm()
    
    var shopArray: [ApiResponse.Result.Shop] = []
    var apiKey: String = ""
    var isLoading = false
    var isLastLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // APIキー読み込み
        let filePath = Bundle.main.path(forResource: "ApiKey", ofType:"plist" )
        let plist = NSDictionary(contentsOfFile: filePath!)!
        apiKey = plist["key"] as! String
        
        updateShopArray(searchText: searchBar.text)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc func refresh() {
        updateShopArray(searchText: searchBar.text)
    }
    
    
    func updateShopArray(appendLoad: Bool = false,searchText: String?) {
        if isLoading {
            return
        }
        if appendLoad && isLastLoaded {
            return
        }
        let startIndex: Int
        if appendLoad {
            startIndex = shopArray.count + 1
        } else {
            startIndex = 1
        }
        isLoading = true
        let parameters: [String: Any] = [
            "key": apiKey,
            "start": startIndex,
            "count": 20,
            "keyword": searchText ?? "",
            "format": "json"
        ]
        AF.request("https://webservice.recruit.co.jp/hotpepper/gourmet/v1/", method: .get, parameters: parameters).responseDecodable(of: ApiResponse.self) { response in
            self.isLoading = false
            if self.tableView.refreshControl!.isRefreshing {
                self.tableView.refreshControl!.endRefreshing()
            }
            switch response.result {
            case .success(let apiResponse):
                if appendLoad {
                    self.shopArray += apiResponse.results.shop
                } else {
                    self.shopArray = apiResponse.results.shop
                    self.isLastLoaded = false
                }
                if apiResponse.results.shop.count == 0 {
                    self.isLastLoaded = true
                }
                self.statusLabel.text = ""
            case .failure(let error):
                print(error)
                self.shopArray = []
                self.isLastLoaded = true
                if let searchText = searchText, searchText.isEmpty {
                    self.statusLabel.text = "検索キーワードを入力してください"
                } else {
                    self.statusLabel.text = "データの取得が失敗しました"
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shopArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let shop = shopArray[indexPath.row]
        let urlString: String
        if shop.coupon_urls.sp == "" {
            urlString = shop.coupon_urls.pc
        } else {
            urlString = shop.coupon_urls.sp
        }
        let url = URL(string: urlString)!
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ShopCell
        let shop = shopArray[indexPath.row]
        let url = URL(string: shop.logo_image)!
        cell.logoImageView.af.setImage(withURL: url)
        cell.shopNameLabel.text = shop.name
        cell.ShopAddressLabel.text = shop.address
        let starImageName = shop.isFavorite ? "star.fill" : "star"
        let starImage = UIImage(systemName: starImageName)?.withRenderingMode(.alwaysOriginal)
        cell.favoriteButton.setImage(starImage, for: .normal)
        if shopArray.count - indexPath.row < 10 {
            self.updateShopArray(appendLoad: true,searchText: searchBar.text)
        }
        
        return cell
    }
    
    @IBAction func tapFavoriteButton(_ sender: UIButton) {
        // ここから
        let point = sender.convert(CGPoint.zero, to: tableView)
        let indexPath = tableView.indexPathForRow(at: point)!
        let shop = shopArray[indexPath.row]
        
        if shop.isFavorite {
            print("「\(shop.name)」をお気に入りから削除します")
            try! realm.write {
                let favoriteShop = realm.object(ofType: FavoriteShop.self, forPrimaryKey: shop.id)!
                realm.delete(favoriteShop)
            }
        } else {
            print("「\(shop.name)」をお気に入りに追加します")
            try! realm.write {
                let favoriteShop = FavoriteShop()
                favoriteShop.id = shop.id
                favoriteShop.name = shop.name
                favoriteShop.address = shop.address
                favoriteShop.logoImageURL = shop.logo_image
                if shop.coupon_urls.sp == "" {
                    favoriteShop.couponURL = shop.coupon_urls.pc
                } else {
                    favoriteShop.couponURL = shop.coupon_urls.sp
                }
                realm.add(favoriteShop)
            }
        }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    // 検索文字列が変更されたときに呼び出されるメソッド
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateShopArray(searchText: searchText)
    }
    
    @IBAction func topScrollbutton(_ sender: Any) {
        if !shopArray.isEmpty {
            // データがある場合の処理（最上部にスクロールする）
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}
