//
//  RDClowMachineCodeBannerView.swift
//  CleanyModal
//
//  Created by Orhun Akmil on 15.08.2024.
//

import UIKit

class RDClowMachineCodeBannerView: UIView {
    
    var clowMachineModel: ClowMachineModel

    var horizontalStackView: UIStackView!
    var verticalStackViewLeft: UIStackView!
    var verticalStackViewRight: UIStackView!
    var bannerTextLabel: UILabel!
    var bannerButtonLabel: UILabel!
    var bannerCodeLabel: UILabel!
    var closeButton: UIButton!

    init(frame: CGRect, clowMachineModel: ClowMachineModel) {
        self.clowMachineModel = clowMachineModel
        super.init(frame: frame)
        setupLabels()
        setFonts()
        setColors()
        setCloseButton()
        layoutContent()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabels() {
        horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)

        verticalStackViewLeft = UIStackView()
        verticalStackViewLeft.axis = .vertical
        verticalStackViewLeft.distribution = .equalSpacing
        verticalStackViewLeft.spacing = 10.0
        verticalStackViewLeft.alignment = .center

        verticalStackViewRight = UIStackView()
        verticalStackViewRight.axis = .vertical
        verticalStackViewRight.distribution = .equalSpacing
        verticalStackViewRight.spacing = 10.0
        verticalStackViewRight.alignment = .center

        bannerTextLabel = UILabel()
        bannerTextLabel.text = clowMachineModel.promocode_banner_text.removeEscapingCharacters()
        bannerTextLabel.numberOfLines = 0
        bannerTextLabel.textAlignment = .center
        bannerTextLabel.contentMode = .center
        bannerTextLabel.baselineAdjustment = .alignCenters

        bannerButtonLabel = UILabel()
        bannerButtonLabel.text = clowMachineModel.promocode_banner_button_label
        bannerButtonLabel.textAlignment = .center

        bannerCodeLabel = UILabel()
        bannerCodeLabel.text = BannerCodeManager.shared.getClowMachineCode()
        bannerCodeLabel.textAlignment = .center

        verticalStackViewLeft.addArrangedSubview(bannerTextLabel)

        verticalStackViewRight.addArrangedSubview(bannerButtonLabel)
        verticalStackViewRight.addArrangedSubview(bannerCodeLabel)

        horizontalStackView.addArrangedSubview(verticalStackViewLeft)
        horizontalStackView.addArrangedSubview(verticalStackViewRight)

        addSubview(horizontalStackView)
    }

    private func setCloseButton() {
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.contentHorizontalAlignment = .right
        closeButton.clipsToBounds = false
        closeButton.setTitleColor(UIColor.white, for: .normal)
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 35.0, weight: .regular)
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 2.5, right: 2.5)
        closeButton.setTitleColor(clowMachineModel.close_button_color.lowercased() == "white" ? .white : .black, for: .normal)
        addSubview(closeButton)
    }

    private func layoutContent() {
        horizontalStackView.leading(to: self, offset: 0, relation: .equal, priority: .required)
        horizontalStackView.trailing(to: self, offset: 0, relation: .equal, priority: .required)
        horizontalStackView.centerX(to: self, priority: .required)
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        closeButton.top(to: self, offset: -5.0)
        closeButton.trailing(to: self, offset: -10.0)
        self.window?.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0.0).isActive = true
        self.window?.topAnchor.constraint(equalTo: self.topAnchor, constant: 0.0).isActive = true
        self.layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private func setFonts() {
        let font = RDHelper.getFont(fontFamily: clowMachineModel.font_family,
                                    fontSize: clowMachineModel.copybutton_text_size,
                                    style: .title2, customFont: clowMachineModel.custom_font_family_ios)
        bannerTextLabel.font = font
        bannerButtonLabel.font = font
        bannerCodeLabel.font = font
    }

    private func setColors() {
        self.backgroundColor = UIColor(hex: clowMachineModel.promocode_banner_background_color)
        horizontalStackView.backgroundColor = UIColor(hex: clowMachineModel.promocode_banner_background_color)
        bannerTextLabel.backgroundColor = UIColor(hex: clowMachineModel.promocode_banner_background_color)
        bannerButtonLabel.backgroundColor = UIColor(hex: clowMachineModel.promocode_banner_background_color)
        bannerCodeLabel.backgroundColor = UIColor(hex: clowMachineModel.promocode_banner_background_color)

        bannerTextLabel.textColor = UIColor(hex: clowMachineModel.promocode_banner_text_color)
        bannerButtonLabel.textColor = UIColor(hex: clowMachineModel.promocode_banner_text_color)
        bannerCodeLabel.textColor = UIColor(hex: clowMachineModel.promocode_banner_text_color)
    }

}
