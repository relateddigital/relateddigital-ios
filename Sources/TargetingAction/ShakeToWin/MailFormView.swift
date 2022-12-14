//
//  MailFormView.swift
//  RelatedDigitalIOS
//
//  Created by Orhun Akmil on 10.11.2022.
//

import UIKit

class MailFormView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTİtleLabel: UILabel!
    @IBOutlet weak var mailTextView: UITextField!
    @IBOutlet weak var firsLineTickLabel: UILabel!
    @IBOutlet weak var firstLineTickImageView: UIImageView!
    @IBOutlet weak var secondLineTickLabel: UILabel!
    @IBOutlet weak var firstLineWarningLabel: UILabel!
    @IBOutlet weak var secondLineTicImageView: UIImageView!
    @IBOutlet weak var secondLineWarningLabel: UILabel!
    @IBOutlet weak var continueButtonView: UIView!
    @IBOutlet weak var continueButtonLabel: UILabel!
    @IBOutlet weak var mailInvalidLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
