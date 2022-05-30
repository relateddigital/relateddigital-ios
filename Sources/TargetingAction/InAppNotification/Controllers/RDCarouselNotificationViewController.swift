//
//  RDCarouselNotificationViewController.swift
//  RelatedDigitalIOS
//
//  Created by Egemen Gülkılık on 14.11.2021.
//

import UIKit

func windowRotationTransform() -> CGAffineTransform {
    let angleInDegrees = rotationAngleToMatchDeviceOrientation(UIDevice.current.orientation)
    let angleInRadians = degreesToRadians(angleInDegrees)
    return CGAffineTransform(rotationAngle: angleInRadians)
}

func deviceRotationTransform() -> CGAffineTransform {
    let angleInDegrees = rotationAngleToMatchDeviceOrientation(UIDevice.current.orientation)
    let angleInRadians = degreesToRadians(angleInDegrees)
    return CGAffineTransform(rotationAngle: -angleInRadians)
}

func degreesToRadians(_ degree: CGFloat) -> CGFloat {
    return CGFloat(Double.pi) * degree / 180
}

private func rotationAngleToMatchDeviceOrientation(_ orientation: UIDeviceOrientation) -> CGFloat {
    var desiredRotationAngle: CGFloat = 0
    switch orientation {
    case .landscapeLeft:                    desiredRotationAngle = 90
    case .landscapeRight:                   desiredRotationAngle = -90
    case .portraitUpsideDown:               desiredRotationAngle = 180
    default:                                desiredRotationAngle = 0
    }
    return desiredRotationAngle
}

func rotationAdjustedBounds() -> CGRect {
    let applicationWindow = UIApplication.shared.delegate?.window?.flatMap { $0 }
    guard let window = applicationWindow else { return UIScreen.main.bounds }
    if UIApplication.isPortraitOnly {
        return (UIDevice.current.orientation.isLandscape) ? CGRect(origin: CGPoint.zero, size: window.bounds.size.inverted()): window.bounds
    }
    return window.bounds
}



public typealias MarginLeft = CGFloat
public typealias MarginRight = CGFloat
public typealias MarginTop = CGFloat
public typealias MarginBottom = CGFloat

/// Represents various possible layouts for the footer
public enum FooterLayout {
    case pinLeft(MarginBottom, MarginLeft)
    case pinRight(MarginBottom, MarginRight)
    case pinBoth(MarginBottom, MarginLeft, MarginRight)
    case center(MarginBottom)
}

public enum ButtonMode {
    case none
    case builtIn /// Standard Close or Thumbnails button.
    case custom(UIButton)
}

public enum GalleryDisplacementStyle {
    case normal
    case springBounce(CGFloat) ///
}

extension UIApplication {

    static var applicationWindow: UIWindow {
        return UIApplication.shared.keyWindow!
    }

    static var isPortraitOnly: Bool {
        let orientations = UIApplication.shared.supportedInterfaceOrientations(for: nil)
        return !(orientations.contains(.landscapeLeft) || orientations.contains(.landscapeRight) || orientations.contains(.landscape))
    }
}

public extension UIScreen {
    class var hasNotch: Bool {
        return main.nativeBounds.size == CGSize(width: 1125, height: 2436)
    }
}

public extension UIViewController {
    func presentCarouselNotification(_ gallery: RDCarouselNotificationViewController, completion: (() -> Void)? = {}) {
        present(gallery, animated: false, completion: completion)
    }
}

extension UIView {

    public var boundsCenter: CGPoint {
        return CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    }

    func frame(inCoordinatesOfView parentView: UIView) -> CGRect {
        let frameInWindow = UIApplication.applicationWindow.convert(self.bounds, from: self)
        return parentView.convert(frameInWindow, from: UIApplication.applicationWindow)
    }

    func addSubviews(_ subviews: UIView...) {
        for view in subviews { self.addSubview(view) }
    }

    static func animateWithDuration(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions(), animations: animations, completion: nil)
    }

    static func animateWithDuration(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions(), animations: animations, completion: completion)
    }
}

extension CGSize {
    func inverted() -> CGSize {
        return CGSize(width: self.height, height: self.width)
    }
}

public typealias ImageCompletion = (UIImage?, UIImage?, RDCarouselItem) -> Void
public typealias FetchImageBlock = (@escaping ImageCompletion) -> Void

public struct RelatedDigitalCarouselItemBlock {
    public var fetchImageBlock: FetchImageBlock?
    public var relatedDigitalCarouselItemView: RDCarouselItemView
    public init(fetchImageBlock: FetchImageBlock?, relatedDigitalCarouselItemView: RDCarouselItemView) {
        self.fetchImageBlock = fetchImageBlock
        self.relatedDigitalCarouselItemView = relatedDigitalCarouselItemView
    }
}

public protocol DisplaceableView {
    var relatedDigitalCarouselItem: RDCarouselItem? { get }
    var bounds: CGRect { get }
    var center: CGPoint { get }
    var boundsCenter: CGPoint { get }
    var contentMode: UIView.ContentMode { get }
    var isHidden: Bool { get set }
    func convert(_ point: CGPoint, to view: UIView?) -> CGPoint
}

extension DisplaceableView {
    func getView() -> UIView {
        let view = RDCarouselItemView(frame: .zero, relatedDigitalCarouselItem: self.relatedDigitalCarouselItem)
        view.bounds = self.bounds
        view.center = self.center
        return view
    }
}

extension DisplaceableView {
    func frameInCoordinatesOfScreen() -> CGRect {
        return UIView().convert(self.bounds, to: UIScreen.main.coordinateSpace)
    }
}

public protocol GalleryDisplacedViewsDataSource: AnyObject {
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView?
}

public protocol ItemController: AnyObject {
    
    var itemView: RDCarouselItemView { get set}
    
    var index: Int { get }
    var isInitialController: Bool { get set }
    var delegate:                 ItemControllerDelegate? { get set }
    var displacedViewsDataSource: GalleryDisplacedViewsDataSource? { get set }
    
    func fetchImage()
    
    func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)
    func dismissItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)
    
    func closeCarousel(shouldTrack: Bool, callToActionURL: URL?)
}


public protocol ItemControllerDelegate: AnyObject {
    
    ///Represents a generic transitioning progress from 0 to 1 (or reversed) where 0 is no progress and 1 is fully finished transitioning. It's up to the implementing controller to make decisions about how this value is being calculated, based on the nature of transition.
    func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat)
    func itemControllerWillAppear(_ controller: ItemController)
    func itemControllerWillDisappear(_ controller: ItemController)
    func itemControllerDidAppear(_ controller: ItemController)
    func fetchedImage(_ controller: ItemController)
    func closeCarousel(shouldTrack: Bool, callToActionURL: URL?)
}

public protocol RelatedDigitalCarouselItemsDataSource: AnyObject {
    func itemCount() -> Int
    func provideGalleryItem(_ index: Int) -> RelatedDigitalCarouselItemBlock
}


public class RDCarouselNotificationViewController: RDBasePageViewController, ItemControllerDelegate {
    
    var carouselNotification: RDInAppNotification! {
        return super.notification
    }
    
    // UI
    fileprivate let overlayView = RDBlurView()
    
    /// A custom view at the bottom of the gallery with layout using default (or custom) pinning settings for footer.
    public var footerView: UIPageControl?
    
    fileprivate weak var initialItemController: ItemController?
    
    // LOCAL STATE
    // represents the current page index, updated when the root view of the view controller representing the page stops animating inside visible bounds and stays on screen.
    public var currentIndex: Int
    // Picks up the initial value from configuration, if provided. Subsequently also works as local state for the setting.
    fileprivate var decorationViewsHidden = false
    fileprivate var isAnimating = false
    fileprivate var initialPresentationDone = false
    
    // DATASOURCE/DELEGATE
    fileprivate var pagingDataSource: RDCarouselPagingDataSource!
    
    // CONFIGURATION
    fileprivate var spineDividerWidth:         Float = 30
    fileprivate var footerLayout = FooterLayout.center(25)
    fileprivate var statusBarHidden = true
    fileprivate var overlayAccelerationFactor: CGFloat = 1
    fileprivate var rotationDuration = 0.15
    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6
    fileprivate var decorationViewsFadeDuration = 0.15
    
    /// COMPLETION BLOCKS
    /// If set, the block is executed right after the initial launch animations finish.
    open var launchedCompletion: (() -> Void)?
    /// If set, called every time ANY animation stops in the page controller stops and the viewer passes a page index of the page that is currently on screen
    open var landedPageAtIndexCompletion: ((Int) -> Void)?
    /// If set, launched after all animations finish when the close button is pressed.
    open var closedCompletion:                 (() -> Void)?
    /// If set, launched after all animations finish when the close() method is invoked via public API.
    open var programmaticallyClosedCompletion: (() -> Void)?
 
    @available(*, unavailable)
    required public init?(coder: NSCoder) { fatalError() }
    
    public init(startIndex: Int, notification: RDInAppNotification) {
        
        overlayView.overlayColor = UIColor(white: 0.035, alpha: 1)
        overlayView.colorTargetOpacity = 0.7
        overlayView.blurTargetOpacity = 0.7
        overlayView.blurringView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
        self.currentIndex = startIndex
        spineDividerWidth = 0.0// TODO: egemen bak sonra
        
        
        super.init(transitionStyle: UIPageViewController.TransitionStyle.scroll,
                   navigationOrientation: UIPageViewController.NavigationOrientation.horizontal,
                   options: [UIPageViewController.OptionsKey.interPageSpacing : NSNumber(value: spineDividerWidth as Float)])
        
        self.notification = notification
        pagingDataSource = RDCarouselPagingDataSource(itemsDataSource: self, displacedViewsDataSource: self, notification: notification)
        pagingDataSource.itemControllerDelegate = self
        
        ///This feels out of place, one would expect even the first presented(paged) item controller to be provided by the paging dataSource but there is nothing we can do as Apple requires the first controller to be set via this "setViewControllers" method.
        let initialController = pagingDataSource.createItemController(startIndex, isInitial: true)
        self.setViewControllers([initialController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        if let controller = initialController as? ItemController {
            
            initialItemController = controller
        }
        
        ///This less known/used presentation style option allows the contents of parent view controller presenting the gallery to "bleed through" the blurView. Otherwise we would see only black color.
        self.modalPresentationStyle = .overFullScreen
        self.dataSource = pagingDataSource
        
        UIApplication.applicationWindow.windowLevel = (statusBarHidden) ? UIWindow.Level.statusBar + 1 : UIWindow.Level.normal
        
        NotificationCenter.default.addObserver(self, selector: #selector(RDCarouselNotificationViewController.rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        
        if notification.closePopupActionType?.lowercased() != "closebutton" {
            let overlayViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(overlayViewTapped(tapGestureRecognizer:)))
            view.gestureRecognizers = []
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(overlayViewTapGestureRecognizer)
        }
        
        //footerView = UIPageControl()
        //footerView?.numberOfPages = notification.carouselItems.count
        //footerView?.currentPage = startIndex
        
    }
    
    @objc func overlayViewTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        self.closeCarousel(shouldTrack: false, callToActionURL: nil)
    }
    
    
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func configureOverlayView() {
        overlayView.bounds.size = UIScreen.main.bounds.insetBy(dx: -UIScreen.main.bounds.width / 2, dy: -UIScreen.main.bounds.height / 2).size
        overlayView.center = CGPoint(x: (UIScreen.main.bounds.width / 2), y: (UIScreen.main.bounds.height / 2))
        self.view.addSubview(overlayView)
        self.view.sendSubviewToBack(overlayView)
    }
    
    
    /*
    fileprivate func configureFooterView() {
        if let footer = footerView {
            footer.alpha = 0
            self.view.addSubview(footer)
        }
    }
     */
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            if (statusBarHidden || UIScreen.hasNotch) {
                additionalSafeAreaInsets = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
            }
        }
        //configureFooterView()
        self.view.clipsToBounds = false
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard initialPresentationDone == false else { return }
        
        ///We have to call this here (not sooner), because it adds the overlay view to the presenting controller and the presentingController property is set only at this moment in the VC lifecycle.
        configureOverlayView()
        
        ///The initial presentation animations and transitions
        presentInitially()
        
        initialPresentationDone = true
    }
    
    fileprivate func presentInitially() {
        
        isAnimating = true
        
        ///Animates decoration views to the initial state if they are set to be visible on launch. We do not need to do anything if they are set to be hidden because they are already set up as hidden by default. Unhiding them for the launch is part of chosen UX.
        initialItemController?.presentItem(alongsideAnimation: { [weak self] in
            self?.overlayView.present()
            
        }, completion: { [weak self] in
            
            if let strongSelf = self {
                
                if strongSelf.decorationViewsHidden == false {
                    
                    strongSelf.animateDecorationViews(visible: true)
                }
                
                strongSelf.isAnimating = false
                
                strongSelf.launchedCompletion?()
            }
        })
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIApplication.isPortraitOnly {
            
            let transform = windowRotationTransform()
            let bounds = rotationAdjustedBounds()
            
            self.view.transform = transform
            self.view.bounds = bounds
        }
        
        overlayView.frame = view.bounds.insetBy(dx: -UIScreen.main.bounds.width * 2, dy: -UIScreen.main.bounds.height * 2)
        //layoutFooterView()
    }
    
    private var defaultInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: statusBarHidden ? 0.0 : 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }

    
    fileprivate func layoutFooterView() {
        
        guard let footer = footerView else { return }
        
        switch footerLayout {
            
        case .center(let marginBottom):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            footer.center = self.view.boundsCenter
            footer.frame.origin.y = self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom
            
        case .pinBoth(let marginBottom, let marginLeft,let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            footer.frame.size.width = self.view.bounds.width - marginLeft - marginRight
            footer.sizeToFit()
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
            
        case .pinLeft(let marginBottom, let marginLeft):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
            
        case .pinRight(let marginBottom, let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            footer.frame.origin = CGPoint(x: self.view.bounds.width - marginRight - footer.bounds.width, y: self.view.bounds.height - footer.bounds.height - marginBottom - defaultInsets.bottom)
        }
    }
    
    
    public func page(toIndex index: Int) {
        
        guard currentIndex != index && index >= 0 && index < self.itemCount() else { return }
        
        let imageViewController = self.pagingDataSource.createItemController(index)
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        
        // workaround to make UIPageViewController happy
        if direction == .forward {
            let previousVC = self.pagingDataSource.createItemController(index - 1)
            setViewControllers([previousVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        } else {
            let nextVC = self.pagingDataSource.createItemController(index + 1)
            setViewControllers([nextVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        }
    }
    
    func removePage(atIndex index: Int, completion: @escaping () -> Void) {
        
        // If removing last item, go back, otherwise, go forward
        
        let direction: UIPageViewController.NavigationDirection = index < self.itemCount() ? .forward : .reverse
        
        let newIndex = direction == .forward ? index : index - 1
        
        if newIndex < 0 { close(); return }
        
        let vc = self.pagingDataSource.createItemController(newIndex)
        setViewControllers([vc], direction: direction, animated: true) { _ in completion() }
    }
    
    open func reload(atIndex index: Int) {
        
        guard index >= 0 && index < self.itemCount() else { return }
        
        guard let firstVC = viewControllers?.first, let itemController = firstVC as? ItemController else { return }
        
        itemController.fetchImage()
    }
    
    // MARK: - Animations
    
    @objc fileprivate func rotate() {
        
        /// If the app supports rotation on global level, we don't need to rotate here manually because the rotation
        /// of key Window will rotate all app's content with it via affine transform and from the perspective of the
        /// gallery it is just a simple relayout. Allowing access to remaining code only makes sense if the app is
        /// portrait only but we still want to support rotation inside the gallery.
        guard UIApplication.isPortraitOnly else { return }
        
        guard UIDevice.current.orientation.isFlat == false &&
                isAnimating == false else { return }
        
        isAnimating = true
        
        UIView.animate(withDuration: rotationDuration, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] () -> Void in
            
            self?.view.transform = windowRotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            
            self?.view.layoutIfNeeded()
            
        })
        { [weak self] finished  in
            
            self?.isAnimating = false
        }
    }
    
    //TODO: gereksizse kaldır
    /// Invoked when closed programmatically
    public func close() {
    }
    
    //TODO: gereksizse kaldır
    /// Invoked when closed via close button
    @objc fileprivate func closeInteractively() {
    }
    

    
    fileprivate func animateDecorationViews(visible: Bool) {
        
        //let targetAlpha: CGFloat = (visible) ? 1 : 0
        
        //UIView.animate(withDuration: decorationViewsFadeDuration, animations: { [weak self] in
        //    self?.footerView?.alpha = targetAlpha
            
        //})
    }
    
    public func itemControllerWillAppear(_ controller: ItemController) {
        
        
    }
    
    public func itemControllerWillDisappear(_ controller: ItemController) {
        
        
    }
    
    public func fetchedImage(_ controller: ItemController) {
        if let notification = notification {
            controller.itemView.footerView?.removeFromSuperview()
            controller.itemView.footerView = UIPageControl()
            controller.itemView.footerView?.numberOfPages = notification.carouselItems.count
            controller.itemView.footerView?.currentPage = controller.index
            controller.itemView.addSubview(controller.itemView.footerView!)
            controller.itemView.footerView?.topToBottom(of: controller.itemView, offset: -30, relation: .equal, priority: .required, isActive: true)
            controller.itemView.footerView?.centerX(to: controller.itemView, isActive: true)
        }
    }
    
    
    public func itemControllerDidAppear(_ controller: ItemController) {
        self.currentIndex = controller.index
        self.landedPageAtIndexCompletion?(self.currentIndex)
        
        if let notification = notification {
            controller.itemView.footerView?.removeFromSuperview()
            controller.itemView.footerView = UIPageControl()
            controller.itemView.footerView?.numberOfPages = notification.carouselItems.count
            controller.itemView.footerView?.currentPage = controller.index
            controller.itemView.addSubview(controller.itemView.footerView!)
            controller.itemView.footerView?.topToBottom(of: controller.itemView, offset: -30, relation: .equal, priority: .required, isActive: true)
            controller.itemView.footerView?.centerX(to: controller.itemView, isActive: true)
        }
    }
    
    
    public func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat) {
        if decorationViewsHidden == false {
            let alpha = 1 - distance * swipeToDismissFadeOutAccelerationFactor
            footerView?.alpha = alpha
        }
        self.overlayView.blurringView.alpha = 1 - distance
        self.overlayView.colorView.alpha = 1 - distance
    }
    
    public func closeCarousel(shouldTrack: Bool, callToActionURL: URL?) {
        
        self.rdDelegate?.notificationShouldDismiss(controller: self,
                                            callToActionURL: callToActionURL,
                                            shouldTrack: shouldTrack,
                                            additionalTrackingProperties: nil)
    }
    
    public override func hide(animated: Bool, completion: @escaping () -> Void) {
        self.overlayView.removeFromSuperview()
        dismiss(animated: true)
        completion()
    }
    
}


extension RDCarouselNotificationViewController: RelatedDigitalCarouselItemsDataSource {
    
    public func itemCount() -> Int {
        return carouselNotification.carouselItems.count
    }
    
    public func provideGalleryItem(_ index: Int) -> RelatedDigitalCarouselItemBlock {
        let carouselItem = carouselNotification.carouselItems[index]
        return RelatedDigitalCarouselItemBlock(fetchImageBlock: carouselItem.fetchImageBlock, relatedDigitalCarouselItemView: RDCarouselItemView(frame: .zero, relatedDigitalCarouselItem: carouselItem))
    }
}

extension RDCarouselNotificationViewController: GalleryDisplacedViewsDataSource {
    public func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        if index < carouselNotification.carouselItems.count {
            return RDCarouselItemView(frame: .zero, relatedDigitalCarouselItem: carouselNotification.carouselItems[index])
        } else {
            return nil
        }
    }
}



final class RDCarouselPagingDataSource: NSObject, UIPageViewControllerDataSource {
    
    
    weak var notification: RDInAppNotification?
    weak var itemControllerDelegate: ItemControllerDelegate?
    fileprivate weak var itemsDataSource:          RelatedDigitalCarouselItemsDataSource?
    fileprivate weak var displacedViewsDataSource: GalleryDisplacedViewsDataSource?
    
    fileprivate var itemCount: Int { return itemsDataSource?.itemCount() ?? 0 }
    
    init(itemsDataSource: RelatedDigitalCarouselItemsDataSource, displacedViewsDataSource: GalleryDisplacedViewsDataSource?, notification: RDInAppNotification?) {
        self.notification = notification
        self.itemsDataSource = itemsDataSource
        self.displacedViewsDataSource = displacedViewsDataSource
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
        let imageController = ItemBaseController(index: itemIndex, itemCount: itemsDataSource.itemCount(), fetchImageBlock: item.fetchImageBlock, relatedDigitalCarouselItemView: item.relatedDigitalCarouselItemView, isInitialController: isInitial, relatedDigitalInAppNotification: notification)
        imageController.delegate = itemControllerDelegate
        imageController.displacedViewsDataSource = displacedViewsDataSource
        return imageController
    }
}



public class ItemBaseController: UIViewController, ItemController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    public var itemView: RDCarouselItemView
    public var relatedDigitalInAppNotification: RDInAppNotification!
    
    let scrollView = UIScrollView()
    public var footerView: UIPageControl?
    
    //DELEGATE / DATASOURCE
    weak public var delegate:                 ItemControllerDelegate?
    weak public var displacedViewsDataSource: GalleryDisplacedViewsDataSource?
    
    //STATE
    public let index: Int
    public var isInitialController = false
    let itemCount: Int
    //var swipingToDismiss: SwipeToDismiss?
    fileprivate var isAnimating = false
    fileprivate var fetchImageBlock: FetchImageBlock?
    
    //CONFIGURATION
    fileprivate var displacementDuration: TimeInterval = 0.0 // 0.55
    fileprivate var reverseDisplacementDuration: TimeInterval = 0.0 // 0.25
    fileprivate var itemFadeDuration: TimeInterval = 0.3
    fileprivate var displacementTimingCurve: UIView.AnimationCurve = .linear
    fileprivate var displacementSpringBounce: CGFloat = 0.7
    fileprivate var displacementKeepOriginalInPlace = false
    fileprivate var displacementInsetMargin: CGFloat = 0
    
    // MARK: - Initializers
    
    public init(index: Int, itemCount: Int, fetchImageBlock: FetchImageBlock?, relatedDigitalCarouselItemView: RDCarouselItemView
                , isInitialController: Bool = false, relatedDigitalInAppNotification: RDInAppNotification?) {
        
        self.relatedDigitalInAppNotification = relatedDigitalInAppNotification
        
        displacementKeepOriginalInPlace = false
        
        self.itemView = relatedDigitalCarouselItemView
        
        self.index = index
        self.itemCount = itemCount
        self.isInitialController = isInitialController
        self.fetchImageBlock = fetchImageBlock
        
        displacementSpringBounce = 1
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .custom
        
        //TODO: egemen
        self.itemView.imageView.isHidden = isInitialController
        
        configureScrollView()
        
    }
    
    @available (*, unavailable)
    required public init?(coder aDecoder: NSCoder) { fatalError() }
    
    
    // MARK: - Configuration
    
    fileprivate func configureScrollView() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.contentOffset = CGPoint.zero
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.delegate = self
    }
    
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    
    fileprivate func createViewHierarchy() {
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        self.view.addSubview(scrollView)
        
    }
    
    // MARK: - View Controller Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        createViewHierarchy()
        fetchImage()
    }
    
    @objc func buttonTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        self.closeCarousel(shouldTrack: true, callToActionURL: self.itemView.relatedDigitalCarouselItem?.linkUrl)
    }
    
    @objc func closeButtonTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        self.closeCarousel(shouldTrack: false, callToActionURL: nil)
    }
    
    public func fetchImage() {
        
        fetchImageBlock? { [weak self] image,  backgroundImage, carouselItem in
            
            DispatchQueue.main.async { [self] in
                if let s = self {
                    s.itemView = RDCarouselItemView(frame: .zero, relatedDigitalCarouselItem: carouselItem)
                    s.scrollView.addSubview(s.itemView)
                    
                    s.itemView.titleColor = carouselItem.titleColor
                    s.itemView.titleFont = carouselItem.titleFont
                    s.itemView.imageView.image = image
                    s.itemView.contentMode = .scaleAspectFill
                    s.itemView.centerYAnchor.constraint(equalTo: s.scrollView.centerYAnchor).isActive = true
                    if s.relatedDigitalInAppNotification?.videourl?.count ?? 0 > 0 {
                        s.itemView.imageHeightConstraint?.constant = s.itemView.imageView.pv_heightForImageView(isVideoExist: true)
                    } else {
                        s.itemView.imageHeightConstraint?.constant = s.itemView.imageView.pv_heightForImageView(isVideoExist: false)
                    }
                    
                    s.itemView.centerX(to: s.scrollView)
                    s.itemView.width(320.0)
                    s.itemView.isAccessibilityElement = true
                    s.scrollView.minimumZoomScale = 1.0
                    s.scrollView.maximumZoomScale = 1.0
                    s.itemView.translatesAutoresizingMaskIntoConstraints = false
                    
                    if let bgColor = carouselItem.backgroundColor {
                        s.itemView.backgroundColor = bgColor
                    }
                    
                    if let backgroundImage = backgroundImage {
                        s.itemView.backgroundColor = UIColor(patternImage: backgroundImage.aspectFittedToHeight(320.0))
                    }
                    
                    
                    if s.relatedDigitalInAppNotification.closePopupActionType?.lowercased() != "backgroundclick" {
                        let closeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(s.closeButtonTapped(tapGestureRecognizer:)))
                        s.itemView.closeButton.isUserInteractionEnabled = true
                        s.itemView.closeButton.gestureRecognizers = []
                        s.itemView.closeButton.addGestureRecognizer(closeTapGestureRecognizer)
                    }
                    
                    let buttonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(s.buttonTapped(tapGestureRecognizer:)))
                    s.itemView.button.isUserInteractionEnabled = true
                    s.itemView.button.gestureRecognizers = []
                    s.itemView.button.addGestureRecognizer(buttonTapGestureRecognizer)
                    
                    s.delegate?.fetchedImage(s)
                    
                    
                    
                    self?.view.setNeedsLayout()
                    self?.view.layoutIfNeeded()
                }
            }
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.itemControllerWillAppear(self)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.itemControllerDidAppear(self)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.itemControllerWillDisappear(self)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = self.view.bounds
        
        if relatedDigitalInAppNotification?.videourl?.count ?? 0 > 0 {
            itemView.imageHeightConstraint?.constant = itemView.imageView.pv_heightForImageView(isVideoExist: true)
        } else {
            itemView.imageHeightConstraint?.constant = itemView.imageView.pv_heightForImageView(isVideoExist: false)
        }
    }
    
    // MARK: - Present/Dismiss transitions
    
    public func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void) {
        itemView.width(320.0)
        guard isAnimating == false else { return }
        isAnimating = true
        
        alongsideAnimation()
        
        if var displacedView = displacedViewsDataSource?.provideDisplacementItem(atIndex: index) {
            
            //Prepare the animated imageView
            let animatedImageView = displacedView.getView()
            
            //rotate the imageView to starting angle
            if UIApplication.isPortraitOnly == true {
                animatedImageView.transform = deviceRotationTransform()
            }
            
            //position the image view to starting center
            animatedImageView.center = displacedView.convert(displacedView.boundsCenter, to: self.view)
            
            animatedImageView.clipsToBounds = true
            self.view.addSubview(animatedImageView)
            
            if displacementKeepOriginalInPlace == false {
                displacedView.isHidden = true
            }
            
            UIView.animate(withDuration: displacementDuration, delay: 0, usingSpringWithDamping: displacementSpringBounce, initialSpringVelocity: 1, options: .curveEaseIn, animations: { [weak self] in
                
                if UIApplication.isPortraitOnly == true {
                    animatedImageView.transform = CGAffineTransform.identity
                }
                /// Animate it into the center (with optionally rotating) - that basically includes changing the size and position
                
                if let size = self?.itemView.bounds.size {
                    animatedImageView.bounds.size = size
                }
                
                animatedImageView.center = self?.view.boundsCenter ?? CGPoint.zero
                
            }, completion: { [weak self] _ in
                
                self?.itemView.isHidden = false
                displacedView.isHidden = false
                animatedImageView.removeFromSuperview()
                
                self?.isAnimating = false
                completion()
            })
        }
        
        else {
            itemView.alpha = 0
            itemView.isHidden = false
            UIView.animate(withDuration: itemFadeDuration, animations: { [weak self] in
                self?.itemView.alpha = 1
            }, completion: { [weak self] _ in
                completion()
                self?.isAnimating = false
            })
        }
    }
    
    func findVisibleDisplacedView() -> DisplaceableView? {
        guard let displacedView = displacedViewsDataSource?.provideDisplacementItem(atIndex: index) else { return nil }
        let displacedViewFrame = displacedView.frameInCoordinatesOfScreen()
        let validAreaFrame = self.view.frame.insetBy(dx: displacementInsetMargin, dy: displacementInsetMargin)
        let isVisibleEnough = displacedViewFrame.intersects(validAreaFrame)
        return isVisibleEnough ? displacedView : nil
    }
    
    public func dismissItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void) {
        guard isAnimating == false else { return }
        isAnimating = true
        alongsideAnimation()
        if var displacedView = self.findVisibleDisplacedView() {
            if displacementKeepOriginalInPlace == false {
                displacedView.isHidden = true
            }
            UIView.animate(withDuration: reverseDisplacementDuration, animations: { [weak self] in
                //rotate the image view
                if UIApplication.isPortraitOnly == true {
                    self?.itemView.transform = deviceRotationTransform()
                }
                self?.itemView.bounds = displacedView.bounds
                self?.itemView.center = displacedView.convert(displacedView.boundsCenter, to: self!.view)
                self?.itemView.clipsToBounds = true
                
            }, completion: { [weak self] _ in
                self?.isAnimating = false
                displacedView.isHidden = false
                completion()
            })
        }
        
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func closeCarousel(shouldTrack: Bool, callToActionURL: URL?) {
        delegate?.closeCarousel(shouldTrack: shouldTrack, callToActionURL: callToActionURL)
    }
}

