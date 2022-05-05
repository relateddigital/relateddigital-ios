//
//  bannerViewController.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 1.05.2022.
//

import UIKit

public class BannerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

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
        self.view.addSubview(bannerView)
        NSLayoutConstraint.activate([bannerView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     bannerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                     bannerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                     bannerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)])
        globalBannerView = bannerView
        
        //For Workable Delegate
        self.willMove(toParent: addedController)
        self.view.frame = view.bounds
        view.addSubview(bannerView)
        addedController.addChild(self)
        self.didMove(toParent: addedController)
        //
        
        bannerView.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "bannerCell")

        bannerView.collectionView.dataSource = self
        bannerView.collectionView.delegate = self
        bannerView.collectionView.contentInset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)

    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bannerCell", for: indexPath)
        cell.contentMode = .center
        
        let cellTemp : bannerCollectionViewCell = UIView.fromNib()
        cellTemp.imageView.backgroundColor = .yellow
        cell.addSubview(cellTemp)
        cellTemp.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([cellTemp.topAnchor.constraint(equalTo: cell.topAnchor),
                                     cellTemp.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                                     cellTemp.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                                     cellTemp.bottomAnchor.constraint(equalTo: cell.bottomAnchor)])


        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.width, height: self.view.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
