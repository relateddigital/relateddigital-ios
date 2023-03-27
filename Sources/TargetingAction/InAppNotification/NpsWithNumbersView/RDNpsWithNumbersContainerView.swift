//
//  RDNpsWithNumbersContainerView.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.03.2023.
//

import Foundation
import UIKit

final public class RDNpsWithNumbersContainerView: UIView {

    internal lazy var shadowContainer: UIView = {
        let shadowContainer = UIView(frame: .zero)
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .yellow
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowContainer.clipsToBounds = false
        return shadowContainer
    }()

    // The container stack view for buttons
    internal lazy var buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.backgroundColor = .clear
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 0
        return buttonStackView
    }()

    internal lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.buttonStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()

    // The preferred width for iPads
    fileprivate var preferredWidth: CGFloat = 0.0

    // MARK: - Constraints

    /// The center constraint of the shadow container
    internal var centerYConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    internal override init(frame: CGRect) {
        self.preferredWidth = UIScreen.main.bounds.width
        print(UIScreen.main.bounds.width)
        print(UIScreen.main.bounds.height)
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0.535, alpha: 0.5)
        setupViews()
        super.layoutIfNeeded()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup

    internal func setupViews() {

        // Add views
        addSubview(shadowContainer)
        shadowContainer.addSubview(stackView)

        // Layout views
        var constraints = [NSLayoutConstraint]()

        // Shadow container constraints
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            shadowContainer.width(preferredWidth)
            shadowContainer.leading(to: self, offset: 0.0, relation: .equalOrGreater, priority: .required)
            shadowContainer.trailing(to: self, offset: 0.0, relation: .equalOrLess, priority: .required)
        } else {
            shadowContainer.width(preferredWidth, relation: .equalOrGreater)
            shadowContainer.leading(to: self, offset: 0, relation: .equal)
            shadowContainer.trailing(to: self, offset: 0, relation: .equal)
        }

        constraints += [NSLayoutConstraint(item: shadowContainer,
                                           attribute: .centerX,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .centerX,
                                           multiplier: 1,
                                           constant: 0)]

        centerYConstraint = NSLayoutConstraint(item: shadowContainer,
                                               attribute: .centerY,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .centerY,
                                               multiplier: 1,
                                               constant: 0)

        if let centerYConstraint = centerYConstraint {
            constraints.append(centerYConstraint)
        }

        stackView.allEdges(to: shadowContainer)

        // Activate constraints
        NSLayoutConstraint.activate(constraints)
    }
}

