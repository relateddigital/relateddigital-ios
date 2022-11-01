//
//  bannerViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 1.05.2022.
//

import UIKit

class BannerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    var globalBannerView : bannerView?
    var bannerViewModel : BannerViewModel?
    var timer = Timer()
    var currentPage = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bannerViewModel?.passAction == .slide {
            startTimer()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    init (view:UIView,addedController:UIViewController,model:AppBannerResponseModel) {
        super.init(nibName: nil, bundle: nil)
        DispatchQueue.main.async { [self] in
            self.view = view
            let bannerView : bannerView = UIView.fromNib()
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(bannerView)
            NSLayoutConstraint.activate([bannerView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                         bannerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                         bannerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                         bannerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
            globalBannerView = bannerView
            bannerViewModel = BannerViewModel()
            bannerViewModel?.pageCount = model.app_banners.count
            if model.transition == "swipe" {
                bannerViewModel?.passAction = .swipe
            } else {
                bannerViewModel?.passAction = .slide
            }
            bannerViewModel?.appBanners = model.app_banners
   
            //For Workable Delegate
            self.willMove(toParent: addedController)
            self.view.frame = view.bounds
            view.addSubview(bannerView)
            addedController.addChild(self)
            self.didMove(toParent: addedController)
            //
            
            globalBannerView?.currentPageLabel.text = "\(1)/\(bannerViewModel?.pageCount ?? 10)"
            globalBannerView?.currentPageView.layer.cornerRadius = 15
            globalBannerView?.currentPageView.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            configureCollectionViewLayout()
        }

    }
    
    func configureCollectionViewLayout() {
        globalBannerView?.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "bannerCell")
        globalBannerView?.collectionView.dataSource = self
        globalBannerView?.collectionView.delegate = self
        globalBannerView?.collectionView.isPagingEnabled = true
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height:  self.view.frame.height - (globalBannerView?.pageControlHeightConstraint.constant ?? 0.0))
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        globalBannerView?.collectionView.collectionViewLayout = layout
        
        if bannerViewModel?.pageControlHidden == true {
            globalBannerView?.pageControlView.isHidden = true
            globalBannerView?.pageControlHeightConstraint.constant = 0.0
        }
        globalBannerView?.pageControlView.numberOfPages = bannerViewModel?.pageCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannerViewModel?.pageCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bannerCell", for: indexPath)
        cell.contentMode = .center
        cell.backgroundColor = .clear
        let cellTemp : bannerCollectionViewCell = UIView.fromNib()
        cellTemp.imageView.setImage(withUrl: bannerViewModel?.appBanners[indexPath.row].img ?? "")
        cell.addSubview(cellTemp)
        cellTemp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cellTemp.topAnchor.constraint(equalTo: cell.topAnchor,constant: 0),
                                     cellTemp.leadingAnchor.constraint(equalTo: cell.leadingAnchor,constant: 0),
                                     cellTemp.trailingAnchor.constraint(equalTo: cell.trailingAnchor,constant: -1),
                                     cellTemp.bottomAnchor.constraint(equalTo: cell.bottomAnchor,constant: 0)])

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.width, height: self.view.height - (globalBannerView?.pageControlHeightConstraint.constant ?? 0.0))
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        globalBannerView?.pageControlView.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        globalBannerView?.currentPageLabel.text = "\(Int(scrollView.contentOffset.x) / Int(scrollView.frame.width) + 1)/\(bannerViewModel?.pageCount ?? 10)"
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedUrl = bannerViewModel?.appBanners[indexPath.row].ios_lnk
        if let url = URL(string: selectedUrl ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func scrollToNextCell() {

        let collectionView = globalBannerView?.collectionView
        let cellSize = CGSize(width: self.view.frame.width, height: self.view.frame.height - (globalBannerView?.pageControlHeightConstraint.constant ?? 0))
        
        if currentPage == bannerViewModel?.pageCount ?? 10 + 1 {
            collectionView?.scrollRectToVisible(CGRect(x: 0, y:  0, width: cellSize.width, height: cellSize.height), animated: true)
            currentPage = 1
            globalBannerView?.pageControlView.currentPage = 0
            globalBannerView?.currentPageLabel.text = "\(currentPage)/\(bannerViewModel?.pageCount ?? 10)"
        } else {
            let contentOffset = collectionView?.contentOffset
            collectionView?.scrollRectToVisible(CGRect(x: contentOffset!.x + cellSize.width, y:  contentOffset!.y, width: cellSize.width, height: cellSize.height), animated: true)
            globalBannerView?.currentPageLabel.text = "\(currentPage+1)/\(bannerViewModel?.pageCount ?? 10)"
            globalBannerView?.pageControlView.currentPage = currentPage 
            currentPage += 1
        }

    }

    func startTimer() {
        globalBannerView?.collectionView.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(scrollToNextCell), userInfo: nil, repeats: true)
    }
}


struct BannerViewModel {
    var pageControlHidden = false
    var pageCount = 5
    var passAction : PassAction? = .slide
    var appBanners = [AppBannerModel]()

}

enum PassAction {
    case swipe
    case slide
}
