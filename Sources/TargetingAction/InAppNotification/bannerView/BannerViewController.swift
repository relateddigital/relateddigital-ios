//
//  bannerViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 1.05.2022.
//

import UIKit

public class BannerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    var globalBannerView : bannerView?
    var bannerViewModel : BannerViewModel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public init (view:UIView,addedController:UIViewController) {
        super.init(nibName: nil, bundle: nil)
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
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bannerViewModel?.pageCount ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bannerCell", for: indexPath)
        cell.contentMode = .center
        cell.backgroundColor = .clear
        let cellTemp : bannerCollectionViewCell = UIView.fromNib()
        cellTemp.imageView.backgroundColor = .yellow
        cell.addSubview(cellTemp)
        cellTemp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cellTemp.topAnchor.constraint(equalTo: cell.topAnchor,constant: 0),
                                     cellTemp.leadingAnchor.constraint(equalTo: cell.leadingAnchor,constant: 0),
                                     cellTemp.trailingAnchor.constraint(equalTo: cell.trailingAnchor,constant: -1),
                                     cellTemp.bottomAnchor.constraint(equalTo: cell.bottomAnchor,constant: 0)])

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.width, height: self.view.height - (globalBannerView?.pageControlHeightConstraint.constant ?? 0.0))
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        globalBannerView?.pageControlView.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        globalBannerView?.currentPageLabel.text = "\(Int(scrollView.contentOffset.x) / Int(scrollView.frame.width) + 1)/\(bannerViewModel?.pageCount ?? 10)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct BannerViewModel {
    var pageControlHidden = false
    var pageCount = 10

}
