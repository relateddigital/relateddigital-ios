//
//  HomeViewController.swift
//  RelatedDigitalExample
//
//  Created by Egemen Gulkilik on 7.07.2021.
//

import UIKit
import RelatedDigitalIOS


class HomeViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeForm()
    }
    
    fileprivate func addOrganizationIdTextRow() -> TextRow {
        return TextRow("orgId") {
            $0.title = "orgId"
            $0.placeholder = "orgId"
            $0.value = "orgId"
        }.onRowValidationChanged { cell, row in
            let rowIndex = row.indexPath!.row
            while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                row.section?.remove(at: rowIndex + 1)
            }
            if !row.isValid {
                for (index, validationMsg) in row.validationErrors.map({ $0.msg }).enumerated() {
                    let labelRow = LabelRow {
                        $0.title = validationMsg
                        $0.cell.height = { 30 }
                    }
                    let indexPath = row.indexPath!.row + index + 1
                    row.section?.insert(labelRow, at: indexPath)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = .white
            headerView.backgroundView?.backgroundColor = .black
            headerView.textLabel?.textColor = .red
        }
    }
    
    private func initializeForm() {
        LabelRow.defaultCellUpdate = { cell, _ in
            cell.contentView.backgroundColor = .red
            cell.textLabel?.textColor = .white
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            cell.textLabel?.textAlignment = .right
            
        }
        
        
        
        
        
        form +++
            Section("createAPI")
            <<< addOrganizationIdTextRow()
    }
    
    
}

