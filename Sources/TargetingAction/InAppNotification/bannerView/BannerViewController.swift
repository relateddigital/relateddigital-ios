//
//  bannerViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 1.05.2022.
//

import UIKit

public class BannerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {

    var globalBannerView : bannerView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    public override func loadView() {

    }
    public init (view:UIView,addedController:UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.view = view
        let bannerView : bannerView = UIView.fromNib()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(bannerView)
//        NSLayoutConstraint.activate([bannerView.topAnchor.constraint(equalTo: self.view.topAnchor),
//                                     bannerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
//                                     bannerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//                                     bannerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
//        globalBannerView = bannerView
        
        
        self.willMove(toParent: self)
        self.view.frame = view.bounds
        view.addSubview(bannerView)
        addedController.addChild(self)
        self.didMove(toParent: self)
        
        
        bannerView.collectionView.dataSource = self
        bannerView.collectionView.delegate = self

    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("selam")
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : bannerCollectionViewCell = UIView.fromNib()
        cell.imageView.backgroundColor = .blue
        
        return cell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
