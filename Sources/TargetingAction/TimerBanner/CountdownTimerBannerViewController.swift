import UIKit

final class CountdownTimerBannerViewController: RDBaseNotificationViewController {

    final class PassthroughWindow: UIWindow {
        var passRectProvider: (() -> CGRect)?
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            guard let r = passRectProvider?() else { return super.point(inside: point, with: event) }
            return r.contains(point)
        }
    }

    private let model: RDCountdownTimerBannerModel
    private let bannerView = CountdownTimerBannerView()
    private var topC: NSLayoutConstraint!
    private var bottomC: NSLayoutConstraint!
    private var timer: Timer?
    private var targetDate: Date?
    weak var urlDelegate: RDStoryURLDelegate?

    init(model: RDCountdownTimerBannerModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    deinit { timer?.invalidate() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
        applyModel()
        resolveTargetDate()
    }

    // MARK: - Window show/hide
    override func show(animated: Bool) {
        makeWindow()
        trackImpression()
        let delay = TimeInterval(model.waitingTime)
        let work = { [weak self] in
            self?.animateIn(animated: animated)
            self?.startTimer()
        }
        if delay > 0 { DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work) } else { work() }
    }

    override func hide(animated: Bool, completion: @escaping () -> Void) {
        timer?.invalidate()
        let dur = animated ? 0.22 : 0
        UIView.animate(withDuration: dur, animations: {
            self.bannerView.transform = CGAffineTransform(translationX: 0, y: self.topC.isActive ? -14 : 14)
            self.bannerView.alpha = 0
            self.window?.alpha = 0
        }, completion: { _ in
            self.window?.isHidden = true
            self.window?.removeFromSuperview()
            self.window = nil
            completion()
        })
    }

    private func makeWindow() {
        if #available(iOS 13.0, *),
           let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
               .first(where: { $0.activationState == .foregroundActive }) {
            let w = PassthroughWindow(frame: scene.coordinateSpace.bounds)
            w.windowScene = scene
            window = w
        } else {
            window = PassthroughWindow(frame: UIScreen.main.bounds)
        }

        guard let w = window as? PassthroughWindow else { return }
        w.rootViewController = self
        w.windowLevel = .alert
        w.alpha = 0
        w.isHidden = false
        w.passRectProvider = { [weak self] in
            guard let self = self else { return .zero }
            return self.bannerView.convert(self.bannerView.bounds, to: self.view)
        }
    }

    private func animateIn(animated: Bool) {
        bannerView.alpha = 0
        bannerView.transform = CGAffineTransform(translationX: 0, y: topC.isActive ? -16 : 16)
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.window?.alpha = 1
            self.bannerView.alpha = 1
            self.bannerView.transform = .identity
        }
    }

    // MARK: - UI & Model
    private func buildUI() {
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 11.0, *) {
            let safe = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                bannerView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 12),
                bannerView.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -12)
            ])
            let top = (model.position_on_page?.lowercased() ?? "topposition") == "topposition"
            topC = bannerView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8)
            // Alta yapışırken ekranın en dibine değil, host uygulamanın alt menüsünün
            // (tab bar) ya da home indicator alanının üstünde duracak şekilde
            // konumlandırılır. Alt kısıt, ekran (view) altına göre hesaplanır.
            bottomC = bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: resolveBottomConstant())
            topC.isActive = top
            bottomC.isActive = !top

            bannerView.onClose = {             self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil) }
            
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
            tap.numberOfTapsRequired = 1
            tap.cancelsTouchesInView = false
            bannerView.pill.isUserInteractionEnabled = true
            bannerView.pill.addGestureRecognizer(tap)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            bannerView.addGestureRecognizer(pan)

        } else {
            // Fallback on earlier versions
        }

    }

    // Banner alta yapışırken bırakılacak alt boşluğu (view altına göre, negatif)
    // hesaplar: host uygulamada görünür bir tab bar varsa onun üstünde, yoksa
    // home indicator üstünde durur.
    private func resolveBottomConstant() -> CGFloat {
        let gap: CGFloat = 8
        let screenH = UIScreen.main.bounds.height
        if let tabBar = hostTabBar(), tabBar.frame.height > 0 {
            let tabTop = tabBar.convert(tabBar.bounds, to: nil).minY
            return -(screenH - tabTop + gap)
        }
        var safeBottom: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeBottom = hostWindow()?.safeAreaInsets.bottom ?? 0
        }
        return -(safeBottom + 16)
    }

    private func hostWindow() -> UIWindow? {
        var windows: [UIWindow] = []
        if #available(iOS 13.0, *) {
            windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        } else {
            windows = UIApplication.shared.windows
        }
        let hosts = windows.filter { !($0 is PassthroughWindow) && $0 !== window }
        return hosts.first(where: { $0.isKeyWindow }) ?? hosts.first
    }

    private func hostTabBar() -> UITabBar? {
        guard let root = hostWindow()?.rootViewController else { return nil }
        return findTabBar(in: root)
    }

    private func findTabBar(in vc: UIViewController) -> UITabBar? {
        if let tab = vc as? UITabBarController, !tab.tabBar.isHidden, tab.tabBar.alpha > 0.01 {
            return tab.tabBar
        }
        if let presented = vc.presentedViewController, let found = findTabBar(in: presented) {
            return found
        }
        for child in vc.children {
            if let found = findTabBar(in: child) { return found }
        }
        return nil
    }

    // Banner'ı dikey olarak sürükler ve bırakıldığında ekranın üst/alt yarısına
    // göre tam üste veya tam alta yapıştırır.
    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        let translation = g.translation(in: view)
        switch g.state {
        case .changed:
            bannerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        case .ended, .cancelled, .failed:
            let predictedCenterY = bannerView.center.y + translation.y
            let snapTop = predictedCenterY < view.bounds.height / 2
            topC.isActive = snapTop
            bottomC.isActive = !snapTop
            UIView.animate(withDuration: 0.25) {
                self.bannerView.transform = .identity
                self.view.layoutIfNeeded()
            }
        default:
            break
        }
    }


    @objc private func didTapView(_ g: UITapGestureRecognizer) {
        guard let s = self.model.ios_lnk,
              let url = URL(string: s),
              !s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { return }
        trackClick()
        RDLogger.info("opening CTA URL: \(url)")
        urlDelegate?.urlClicked(url)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }

    private func applyModel() {
        // Colors
        bannerView.backgroundColor = UIColor.clear
        
        bannerView.setPillColor(UIColor(hex: model.background_color) ?? UIColor(white: 0.12, alpha: 1))
    
        bannerView.setBodyTextColor(UIColor(hex: model.content_body_text_color) ?? .white)
        
        bannerView.setCounterColors(
            bg: UIColor(hex: model.counter_color)?.withAlphaComponent(0.25) ?? UIColor.black.withAlphaComponent(0.25),
            tile: UIColor(hex: model.scratch_color) ?? UIColor.black,
            text: UIColor(hex: model.counter_color) ?? .white)
        
        if model.close_button_color == "black" {
            bannerView.setCloseColor(UIColor.black)
        } else {
            bannerView.setCloseColor(UIColor.white)
        }
        
        bannerView.setAccentColor(UIColor(hex: model.scratch_color) ?? UIColor.black.withAlphaComponent(0.25))


        
        // Content
        bannerView.setBody(model.content_body ?? "")
        if let url = model.img { ImageLoader.load(from: url, into: bannerView.iconView) }
    }

    private func resolveTargetDate() {
        targetDate = Self.resolveTargetDate(for: model)
    }

    // Modelden geri sayım hedef tarihini çözer (statik; gösterimden önce kontrol için).
    static func resolveTargetDate(for model: RDCountdownTimerBannerModel) -> Date? {
        // txtStartDate öncelikli (“dd.MM.yyyy HH:mm” veya “dd.MM.yyyy”)
        if let s = model.txtStartDate, let d = parseDate(s) { return d }
        if let d = model.counter_Date, let t = model.counter_Time, let date = parseDate("\(d) \(t)") { return date }
        if let d = model.counter_Date, let date = parseDate(d) { return date }
        return nil
    }

    // Geri sayım süresi dolmuşsa banner gösterilmemelidir.
    static func isExpired(model: RDCountdownTimerBannerModel) -> Bool {
        guard let target = resolveTargetDate(for: model) else { return false }
        return target <= Date()
    }

    // MARK: - Countdown
    private func startTimer() {
        guard let target = targetDate else { bannerView.updateSegments(days: 0, hours: 0, minutes: 0); return }
        tick(to: target)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.tick(to: target)
        })
    }

    private func tick(to target: Date) {
        let remain = max(0, Int(target.timeIntervalSinceNow))
        if remain <= 0 {
            bannerView.updateSegments(days: 0, hours: 0, minutes: 0)
            self.delegate?.notificationShouldDismiss(controller: self, callToActionURL: nil, shouldTrack: false, additionalTrackingProperties: nil)
            return
        }
        let d = remain / 86_400
        let h = (remain % 86_400) / 3_600
        let m = (remain % 3_600) / 60
        bannerView.updateSegments(days: d, hours: h, minutes: m)
    }



    // MARK: - Tracking
    private func trackImpression() {
        guard let impression = model.report?.impression, !impression.isEmpty else { return }
        let properties = parseQueryString(impression)
        RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
    }

    private func trackClick() {
        guard let click = model.report?.click, !click.isEmpty else { return }
        let properties = parseQueryString(click)
        RelatedDigital.customEvent(RDConstants.omEvtGif, properties: properties)
    }

    private func parseQueryString(_ query: String) -> [String: String] {
        var dict = [String: String]()
        let pairs = query.components(separatedBy: "&")
        for pair in pairs {
            let elements = pair.components(separatedBy: "=")
            if elements.count == 2 {
                dict[elements[0]] = elements[1]
            }
        }
        return dict
    }

    private static func parseDate(_ raw: String) -> Date? {
        let cal = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "Europe/Istanbul")
        let loc = Locale(identifier: "tr_TR")

        let f1 = DateFormatter()
        f1.calendar = cal; f1.timeZone = tz; f1.locale = loc
        f1.dateFormat = "dd.MM.yyyy HH:mm"
        if let d = f1.date(from: raw) { return d }

        let f2 = DateFormatter()
        f2.calendar = cal; f2.timeZone = tz; f2.locale = loc
        f2.dateFormat = "dd.MM.yyyy"
        if let d = f2.date(from: raw) { return d }

        return nil
    }
}
