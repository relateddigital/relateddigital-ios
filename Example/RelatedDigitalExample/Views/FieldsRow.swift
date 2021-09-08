//
//  FieldsRow.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//


import UIKit

class TextCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences
        textField.keyboardType = .default
    }
}

class IntCell: _FieldCell<Int>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .none
        textField.keyboardType = .numberPad
    }
}

class PhoneCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.keyboardType = .phonePad
        if #available(iOS 10,*) {
            textField.textContentType = .telephoneNumber
        }
    }
}

class NameCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.keyboardType = .asciiCapable
        if #available(iOS 10,*) {
            textField.textContentType = .name
        }
    }
}

class EmailCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .emailAddress
        if #available(iOS 10,*) {
            textField.textContentType = .emailAddress
        }
    }
}

class PasswordCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
        if let textLabel = textLabel {
            textField.setContentHuggingPriority(textLabel.contentHuggingPriority(for: .horizontal) - 1, for: .horizontal)
        }
        if #available(iOS 11,*) {
            textField.textContentType = .password
        }
    }
}

class DecimalCell: _FieldCell<Double>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.keyboardType = .decimalPad
    }
}

class URLCell: _FieldCell<URL>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .URL
        if #available(iOS 10,*) {
            textField.textContentType = .URL
        }
    }
}

class TwitterCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .twitter
    }
}

class AccountCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        if #available(iOS 11,*) {
            textField.textContentType = .username
        }
    }
}

class ZipCodeCell: _FieldCell<String>, CellType {

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.keyboardType = .numbersAndPunctuation
        if #available(iOS 10,*) {
            textField.textContentType = .postalCode
        }
    }
}

class _TextRow: FieldRow<TextCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _IntRow: FieldRow<IntCell> {
    required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        formatter = numberFormatter
    }
}

class _PhoneRow: FieldRow<PhoneCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _NameRow: FieldRow<NameCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _EmailRow: FieldRow<EmailCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _PasswordRow: FieldRow<PasswordCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _DecimalRow: FieldRow<DecimalCell> {
    required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        formatter = numberFormatter
    }
}

class _URLRow: FieldRow<URLCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _AccountRow: FieldRow<AccountCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _ZipCodeRow: FieldRow<ZipCodeCell> {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter arbitrary text.
final class TextRow: _TextRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter names. Biggest difference to TextRow is that it autocapitalization is set to Words.
final class NameRow: _NameRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter secure text.
final class PasswordRow: _PasswordRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter an email address.
final class EmailRow: _EmailRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A String valued row where the user can enter a simple account username.
final class AccountRow: _AccountRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row where the user can enter an integer number.
final class IntRow: _IntRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row where the user can enter a decimal number.
final class DecimalRow: _DecimalRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

/// A row where the user can enter an URL. The value of this row will be a URL.
final class URLRow: _URLRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}
