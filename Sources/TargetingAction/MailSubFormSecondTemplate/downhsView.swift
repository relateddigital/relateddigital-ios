//
//  downhsView.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 13.04.2022.
//

import UIKit

class downhsView: UIView {

    @IBOutlet weak var leftImageVİew: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var rightImageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var leftImageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleUpLabel: UILabel!
    @IBOutlet weak var subTitleDownLabel: UILabel!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var consentLabel: UILabel!
    @IBOutlet weak var downHsBackGroundView: UIView!
    @IBOutlet weak var mailPermitLabel: UILabel!
    @IBOutlet weak var emailPermitCheckBoxImageView: UIImageView!
    @IBOutlet weak var consentPermitCheckBoxImageView: UIImageView!
    @IBOutlet weak var mailErrLabel: UILabel!
    @IBOutlet weak var consentErrLabel: UILabel!
    @IBOutlet weak var emailPermitView: UIView!
    @IBOutlet weak var consentView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

}
