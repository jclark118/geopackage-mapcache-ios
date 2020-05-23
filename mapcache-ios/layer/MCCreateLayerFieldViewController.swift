//
//  MCLayerDetailsViewController.swift
//  mapcache-ios
//
//  Created by Tyler Burgett on 5/19/20.
//  Copyright © 2020 NGA. All rights reserved.
//

import UIKit

protocol MCCreateLayerFieldDelegate: AnyObject {
    func createField(name:String, type:GPKGDataType)
}


class MCCreateLayerFieldViewController: NGADrawerViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MCDualButtonCellDelegate {
    
    var cellArray: Array<UITableViewCell> = []
    var featureTable: MCFeatureTable = MCFeatureTable()
    var tableView: UITableView = UITableView()
    var haveScrolled: Bool = false
    var contentOffset: CGFloat = 0.0
    var fieldName: MCFieldWithTitleCell?
    var dualButtons: MCDualButtonCell?
    weak var createLayerFieldDelegate:MCCreateLayerFieldDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bounds: CGRect = self.view.bounds
        let insetBounds: CGRect = CGRect.init(x: bounds.origin.x, y: bounds.origin.y + 32, width: bounds.size.width, height: bounds.size.height)
        self.tableView = UITableView.init(frame: insetBounds, style: UITableView.Style.plain)
        self.tableView.autoresizingMask.insert(.flexibleWidth)
        self.tableView.autoresizingMask.insert(.flexibleHeight)
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 140
        self.tableView.rowHeight = UITableView.automaticDimension
        // ??? self.edgesForExtendedLayout =
        self.extendedLayoutIncludesOpaqueBars = false
        self.automaticallyAdjustsScrollViewInsets = false
        
        addAndConstrainSubview(self.tableView)
        registerCellTypes()
        initCellArray()
        addDragHandle()
        addCloseButton()
    }
    

    func registerCellTypes() {
        self.tableView.register(UINib.init(nibName: "MCTitleCell", bundle: nil), forCellReuseIdentifier: "title")
        self.tableView.register(UINib.init(nibName: "MCFieldWithTitleCell", bundle: nil), forCellReuseIdentifier: "fieldWithTitle")
        self.tableView.register(UINib.init(nibName: "MCSegmentedControlCell", bundle: nil), forCellReuseIdentifier: "segmentedControl")
        self.tableView.register(UINib.init(nibName: "MCDualButtonCell", bundle: nil), forCellReuseIdentifier: "dualButtons")
    }
    
    
    func initCellArray() {
        self.cellArray.removeAll()
        
        let titleCell:MCTitleCell = self.tableView.dequeueReusableCell(withIdentifier: "title") as! MCTitleCell
        titleCell.setLabelText("New Field")
        cellArray.append(titleCell)
        
        self.fieldName = (self.tableView.dequeueReusableCell(withIdentifier: "fieldWithTitle") as! MCFieldWithTitleCell)
        self.fieldName?.setTitleText("Name")
        self.fieldName?.useReturnKeyDone()
        self.fieldName?.setTextFielDelegate(self)
        self.cellArray.append(self.fieldName!)
        
        //let segmentedControl = (self.tableView.dequeueReusableCell(withIdentifier: "segmentedControl") as! MCSegmentedControlCell)
        
        self.dualButtons = (self.tableView.dequeueReusableCell(withIdentifier: "dualButtons") as! MCDualButtonCell)
        self.dualButtons?.setLeftButtonLabel("Cancel")
        self.dualButtons?.leftButtonAction = "cancel"
        self.dualButtons?.setRightButtonLabel("Save")
        self.dualButtons?.rightButtonAction = "save"
        //TODO: until we have a valid field name, don't enable the button
        self.dualButtons?.dualButtonDelegate = self
        self.cellArray.append(dualButtons!)
    }
    

    override func closeDrawer() {
        self.drawerViewDelegate.popDrawer()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO: validate the name before making the button active
    }
    
    
    // MARK: UITableViewDataSource and UITableViewDelegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellArray[indexPath.row]
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.haveScrolled) {
            rollUpPanGesture(scrollView.panGestureRecognizer, with: scrollView)
        }
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.haveScrolled = true
        
        if (!self.isFullView) {
            scrollView.isScrollEnabled = false
            scrollView.isScrollEnabled = true
        } else {
            scrollView.isScrollEnabled = true
        }
    }
    
    func performDualButtonAction(_ action: String) {
        if (action == "save") {
            self.createLayerFieldDelegate?.createField(name: (self.fieldName?.fieldValue())!, type: GPKG_DT_TEXT)
        } else if (action == "cancel") {
            
        }
    }
}
