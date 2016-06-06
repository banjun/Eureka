//
//  ImageRow.swift
//  Eureka
//
//  Created by Martin Barreto on 2/23/16.
//  Copyright © 2016 Xmartlabs. All rights reserved.
//

import Foundation

public struct ImageRowSourceTypes : OptionSet {
    
    public let rawValue: Int
    public var imagePickerControllerSourceTypeRawValue: Int { return self.rawValue >> 1 }
    
    public init(rawValue: Int) { self.rawValue = rawValue }
    private init(_ sourceType: UIImagePickerControllerSourceType) { self.init(rawValue: 1 << sourceType.rawValue) }
    
    public static let PhotoLibrary  = ImageRowSourceTypes(.photoLibrary)
    public static let Camera  = ImageRowSourceTypes(.camera)
    public static let SavedPhotosAlbum = ImageRowSourceTypes(.savedPhotosAlbum)
    public static let All: ImageRowSourceTypes = [Camera, PhotoLibrary, SavedPhotosAlbum]
    
}

extension ImageRowSourceTypes {
    
// MARK: Helpers
    
    private var localizedString: String {
        switch self {
        case ImageRowSourceTypes.Camera:
            return "Take photo"
        case ImageRowSourceTypes.PhotoLibrary:
            return "Photo Library"
        case ImageRowSourceTypes.SavedPhotosAlbum:
            return "Saved Photos"
        default:
            return ""
        }
    }
}

public enum ImageClearAction {
    case No
    case Yes(style: UIAlertActionStyle)
}

//MARK: Row

public class _ImageRow<Cell: CellType where Cell: BaseCell, Cell: TypedCellType, Cell.Value == UIImage>: SelectorRow<UIImage, Cell, ImagePickerController> {
    

    public var sourceTypes: ImageRowSourceTypes
    public internal(set) var imageURL: NSURL?
    public var clearAction = ImageClearAction.Yes(style: .destructive)
    
    private var _sourceType: UIImagePickerControllerSourceType = .camera
    
    public required init(tag: String?) {
        sourceTypes = .All
        super.init(tag: tag)
        presentationMode = .PresentModally(controllerProvider: ControllerProvider.Callback { return ImagePickerController() }, completionCallback: { [weak self] vc in
            self?.select()
            vc.dismiss(animated: true, completion: nil)
            })
        self.displayValueFor = nil
        
    }
    
    // copy over the existing logic from the SelectorRow
    private func displayImagePickerController(sourceType: UIImagePickerControllerSourceType) {
        if let presentationMode = presentationMode where !isDisabled {
            if let controller = presentationMode.createController(){
                controller.row = self
                controller.sourceType = sourceType
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: cell.formViewController()!)
            }
            else{
                _sourceType = sourceType
                presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: cell.formViewController()!)
            }
        }
    }
    
    public override func customDidSelect() {
        guard !isDisabled else {
            super.customDidSelect()
            return
        }
        deselect()
        var availableSources: ImageRowSourceTypes = []
            
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            _ = availableSources.insert(.PhotoLibrary)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            _ = availableSources.insert(.Camera)
        }
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            _ = availableSources.insert(.SavedPhotosAlbum)
        }

        sourceTypes.formIntersection(availableSources)
        
        if sourceTypes.isEmpty {
            super.customDidSelect()
            return
        }
        
        // now that we know the number of actions aren't empty
        let sourceActionSheet = UIAlertController(title: nil, message: selectorTitle, preferredStyle: .actionSheet)
        guard let tableView = cell.formViewController()?.tableView  else { fatalError() }
        if let popView = sourceActionSheet.popoverPresentationController {
            popView.sourceView = tableView
            popView.sourceRect = tableView.convert(cell.accessoryView?.frame ?? cell.contentView.frame, from: cell)
        }
        createOptionsForAlertController(alertController: sourceActionSheet)
        if case .Yes(let style) = clearAction where value != nil {
            let clearPhotoOption = UIAlertAction(title: NSLocalizedString("Clear Photo", comment: ""), style: style, handler: { [weak self] _ in
                self?.value = nil
                self?.updateCell()
                })
            sourceActionSheet.addAction(clearPhotoOption)
        }
        // check if we have only one source type given
        if sourceActionSheet.actions.count == 1 {
            if let imagePickerSourceType = UIImagePickerControllerSourceType(rawValue: sourceTypes.imagePickerControllerSourceTypeRawValue) {
                displayImagePickerController(sourceType: imagePickerSourceType)
            }
        } else {
            let cancelOption = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler:nil)
            sourceActionSheet.addAction(cancelOption)
            
            if let presentingViewController = cell.formViewController() {
                presentingViewController.present(sourceActionSheet, animated: true, completion:nil)
            }
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue) {
        super.prepareForSegue(segue: segue)
        guard let rowVC = segue.destinationViewController as? ImagePickerController else {
            return
        }
        rowVC.sourceType = _sourceType
    }
    
    public override func customUpdateCell() {
        super.customUpdateCell()
        cell.accessoryType = .none
        if let image = self.value {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true
            cell.accessoryView = imageView
        }
        else{
            cell.accessoryView = nil
        }
    }
    

}

extension _ImageRow {
    
//MARK: Helpers
    
    private func createOptionForAlertController(alertController: UIAlertController, sourceType: ImageRowSourceTypes) {
        guard let pickerSourceType = UIImagePickerControllerSourceType(rawValue: sourceType.imagePickerControllerSourceTypeRawValue) where sourceTypes.contains(sourceType) else { return }
        let option = UIAlertAction(title: NSLocalizedString(sourceType.localizedString, comment: ""), style: .default, handler: { [weak self] _ in
            self?.displayImagePickerController(sourceType: pickerSourceType)
        })
        alertController.addAction(option)
    }
    
    private func createOptionsForAlertController(alertController: UIAlertController) {
        createOptionForAlertController(alertController: alertController, sourceType: .Camera)
        createOptionForAlertController(alertController: alertController, sourceType: .PhotoLibrary)
        createOptionForAlertController(alertController: alertController, sourceType: .SavedPhotosAlbum)
    }
}

/// A selector row where the user can pick an image
public final class ImageRow : _ImageRow<PushSelectorCell<UIImage>>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

