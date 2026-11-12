//
//  RDInstallTracker.swift
//  RelatedDigitalIOS
//

import Foundation
import StoreKit

public enum RDInstallType: String {
    case firstInstall = "first_install"
    case reinstall = "reinstall"
}

public final class RDInstallTracker {

    public static let shared = RDInstallTracker()

    private let lock = NSLock()
    private var _initialInstallType: RDInstallType = .firstInstall
    private var _isStoreKitEvaluated = false

    /// Bu cihaz kurulumunun ilk kez mi yoksa reinstall mi olduğunu döner.
    public var initialInstallType: RDInstallType {
        lock.lock()
        defer { lock.unlock() }
        return _initialInstallType
    }

    /// İlk kurulumun ilk oturumunda olup olmadığını döner (veya ilk indirme durumu).
    public var isFirstInstall: Bool {
        return initialInstallType == .firstInstall
    }

    /// Yeniden kurulum durumunda olup olmadığını döner.
    public var isReinstall: Bool {
        return initialInstallType == .reinstall
    }

    public var isFirstInstallString: String {
        return isFirstInstall ? "1" : "0"
    }

    public var isReinstallString: String {
        return isReinstall ? "1" : "0"
    }

    private init() {
        evaluateInstallStatus()
        evaluateStoreKitAccountPurchaseIfAvailable()
    }

    /// Cihaz düzeyinde Keychain ve UserDefaults kıyası ile ilk kurulum / reinstall tespitini yapar.
    private func evaluateInstallStatus() {
        lock.lock()
        defer { lock.unlock() }

        let defaults = UserDefaults.standard
        let hasUserDefaultsInstall = defaults.bool(forKey: RDConstants.userDefaultsInstalledKey)
        let keychainInstalled = RDKeychain.get(RDConstants.keychainInstalledKey)

        if hasUserDefaultsInstall {
            // Bu kurulum daha önce tespit edilmiş (normal sonraki açılışlar)
            if let savedTypeRaw = defaults.string(forKey: RDConstants.userDefaultsInstallTypeKey),
               let savedType = RDInstallType(rawValue: savedTypeRaw) {
                _initialInstallType = savedType
            } else {
                _initialInstallType = (keychainInstalled == "true") ? .reinstall : .firstInstall
            }
            return
        }

        // UserDefaults boş -> Uygulama ya ilk kez açılıyor ya da silinip tekrar indirilmiş!
        if keychainInstalled == "true" {
            // Keychain\x27de kayıt var ama UserDefaults boş -> REINSTALL!
            _initialInstallType = .reinstall
            RDLogger.info("RDInstallTracker: App reinstall detected via Keychain.")
        } else {
            // Ne Keychain\x27de ne UserDefaults\x27ta kayıt yok -> FIRST INSTALL!
            _initialInstallType = .firstInstall
            RDLogger.info("RDInstallTracker: First install detected.")

            // Gelecekteki reinstall\x27ları yakalayabilmek için Keychain\x27e yaz
            RDKeychain.set("true", forKey: RDConstants.keychainInstalledKey)
            let isoDate = RDHelper.formatDate(Date())
            RDKeychain.set(isoDate, forKey: RDConstants.keychainInstallDateKey)
        }

        // Mevcut kurulum için UserDefaults\x27a kaydet
        defaults.set(true, forKey: RDConstants.userDefaultsInstalledKey)
        defaults.set(_initialInstallType.rawValue, forKey: RDConstants.userDefaultsInstallTypeKey)
        defaults.synchronize()
    }

    /// StoreKit 2 (iOS 16.0+) üzerinden Apple ID seviyesinde daha önce satın alma/indirme olup olmadığını inceler.
    /// Kullanıcı yeni telefon almış olsa dahi, Apple ID\x27de bu uygulama daha önce indirilmişse reinstall olarak işaretler.
    private func evaluateStoreKitAccountPurchaseIfAvailable() {
        if #available(iOS 16.0, *) {
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let verificationResult = try await AppTransaction.shared
                    switch verificationResult {
                    case .verified(let appTransaction):
                        let originalPurchaseDate = appTransaction.originalPurchaseDate
                        let now = Date()
                        if now.timeIntervalSince(originalPurchaseDate) > 3600 {
                            self.markAsReinstallFromStoreKit(originalDate: originalPurchaseDate)
                        }
                    case .unverified(_, let error):
                        RDLogger.warn("RDInstallTracker: StoreKit AppTransaction unverified: \(error)")
                    }
                } catch {
                    RDLogger.warn("RDInstallTracker: StoreKit AppTransaction fetch error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func markAsReinstallFromStoreKit(originalDate: Date) {
        lock.lock()
        defer { lock.unlock() }

        if _initialInstallType != .reinstall {
            _initialInstallType = .reinstall
            RDLogger.info("RDInstallTracker: StoreKit 2 detected prior purchase on Apple ID (\(originalDate)). Updated to reinstall.")

            let defaults = UserDefaults.standard
            defaults.set(RDInstallType.reinstall.rawValue, forKey: RDConstants.userDefaultsInstallTypeKey)
            defaults.synchronize()

            RDKeychain.set("true", forKey: RDConstants.keychainInstalledKey)
        }
    }

    /// customEvent içerisine eklenecek OM.is_first_install değerini belirler.
    public func isFirstInstallValue(tvc: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        if _initialInstallType == .firstInstall && tvc <= 1 {
            return "1"
        }
        return "0"
    }

    /// customEvent içerisine eklenecek OM.is_reinstall değerini belirler.
    public func isReinstallValue(tvc: Int) -> String {
        lock.lock()
        defer { lock.unlock() }
        if _initialInstallType == .reinstall && tvc <= 1 {
            return "1"
        }
        return "0"
    }

    /// Test / Debug amaçlı sıfırlama metodu
    public func resetForTesting() {
        lock.lock()
        defer { lock.unlock() }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: RDConstants.userDefaultsInstalledKey)
        defaults.removeObject(forKey: RDConstants.userDefaultsInstallTypeKey)
        defaults.synchronize()
        RDKeychain.delete(RDConstants.keychainInstalledKey)
        RDKeychain.delete(RDConstants.keychainInstallDateKey)
        _initialInstallType = .firstInstall
    }
}
