//
//  RDCarouselPagingDataSource.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 5.07.2022.
//

import UIKit

final class RDCarouselPagingDataSource: NSObject, UIPageViewControllerDataSource {

    weak var notification: RDInAppNotification?
    weak var itemControllerDelegate: ItemControllerDelegate?
    fileprivate weak var itemsDataSource: RDCarouselItemsDataSource?
    fileprivate weak var displacedViewsDataSource: GalleryDisplacedViewsDataSource?

    fileprivate var itemCount: Int { return itemsDataSource?.itemCount() ?? 0 }

    init(itemsDataSource: RDCarouselItemsDataSource, displacedViewsDataSource: GalleryDisplacedViewsDataSource?, notification: RDInAppNotification?) {
        self.notification = notification
        self.itemsDataSource = itemsDataSource
        self.displacedViewsDataSource = displacedViewsDataSource
        // TODO: egemen buna bak sonra. tek elemanlı carousel olabilir mi?
        // Potential carousel mode present in configuration only makes sense for more than 1 item

    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let currentController = viewController as? ItemController else { return nil }
        let previousIndex = (currentController.index == 0) ? itemCount - 1 : currentController.index - 1

        return (currentController.index > 0) ? self.createItemController(previousIndex) : nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let currentController = viewController as? ItemController  else { return nil }
        let nextIndex = (currentController.index == itemCount - 1) ? 0 : currentController.index + 1

        return (currentController.index < itemCount - 1) ? self.createItemController(nextIndex) : nil
    }

    func createItemController(_ itemIndex: Int, isInitial: Bool = false) -> UIViewController {
        guard let itemsDataSource = itemsDataSource else { return UIViewController() }
        let item = itemsDataSource.provideGalleryItem(itemIndex)
        let imageController = ItemBaseController(index: itemIndex, itemCount: itemsDataSource.itemCount(), fetchImageBlock: item.fetchImageBlock, rdCarouselItemView: item.rdCarouselItemView, isInitialController: isInitial, rdInAppNotification: notification)
        imageController.delegate = itemControllerDelegate
        imageController.displacedViewsDataSource = displacedViewsDataSource
        return imageController
    }
}
