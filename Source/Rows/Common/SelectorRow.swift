//
//  SelectorRow.swift
//  Eureka
//
//  Created by Martin Barreto on 2/23/16.
//  Copyright © 2016 Xmartlabs. All rights reserved.
//

import Foundation

public class PushSelectorCell<T: Equatable> : Cell<T>, CellType {
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public override func update() {
        super.update()
        accessoryType = .disclosureIndicator
        editingAccessoryType = accessoryType
        selectionStyle = row.isDisabled ? .none : .default
    }
}

/// Generic row type where a user must select a value among several options.
public class SelectorRow<T: Equatable, Cell: BaseCell, VCType: TypedRowControllerType where Cell: TypedCellType, VCType: UIViewController>: OptionsRow<T, Cell>, PresenterRowType {
    
    /// Defines how the view controller will be presented, pushed, etc.
    public var presentationMode: PresentationMode<VCType>?
    
    /// Will be called before the presentation occurs.
    public var onPresentCallback : ((FormViewController, VCType)->())?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
    
    /**
     Extends `didSelect` method
     */
    public override func customDidSelect() {
        super.customDidSelect()
        guard let presentationMode = presentationMode where !isDisabled else { return }
        if let controller = presentationMode.createController(){
            controller.row = unsafeBitCast(self, to: RowOf<VCType.RowValue>.self)
            controller.title = selectorTitle ?? controller.title
            onPresentCallback?(cell.formViewController()!, controller)
            presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: self.cell.formViewController()!)
        }
        else{
            presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: self.cell.formViewController()!)
        }
    }
    
    /**
     Prepares the pushed row setting its title and completion callback.
     */
    public override func prepareForSegue(segue: UIStoryboardSegue) {
        super.prepareForSegue(segue: segue)
        guard let rowVC = segue.destinationViewController as? VCType else { return }
        rowVC.title = selectorTitle ?? rowVC.title
        rowVC.completionCallback = presentationMode?.completionHandler ?? rowVC.completionCallback
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = unsafeBitCast(self, to: RowOf<VCType.RowValue>.self)
    }
}
