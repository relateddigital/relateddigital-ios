//
//  CupponCodePageView.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 10.11.2022.
//

import UIKit

class CupponCodePageView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var cupponCodeView: UIView!
    @IBOutlet weak var cupponCodeLabel: UILabel!
    @IBOutlet weak var copyButtonView: UIView!
    @IBOutlet weak var coppyButtonLabel: UILabel!
    @IBOutlet weak var goLinkVİew: UIView!
    @IBOutlet weak var goLinkLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
