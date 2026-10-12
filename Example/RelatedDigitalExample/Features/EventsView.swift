//
//  EventsView.swift
//  RelatedDigitalExample
//
//  Analytics surface. Every row sends a real event; the disclosure shows the
//  exact payload that will reach `RelatedDigital.customEvent` first, so the
//  request can be verified against the panel field by field.
//

import RelatedDigitalIOS
import SwiftUI

// MARK: - Catalog

/// One sendable analytics event, described declaratively.
struct AnalyticsAction: Identifiable {

    enum Group: String, CaseIterable, Identifiable {
        case identity = "Identity"
        case browsing = "Browsing"
        case commerce = "Commerce"
        case engagement = "Engagement"
        case system = "System"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .identity: return "person.crop.circle.fill"
            case .browsing: return "eye.fill"
            case .commerce: return "cart.fill"
            case .engagement: return "hand.tap.fill"
            case .system: return "gearshape.2.fill"
            }
        }
    }

    /// What the row actually invokes on the SDK.
    enum Call {
        case customEvent(pageName: String)
        case login(withExtras: Bool)
        case signUp
        case logout
        case campaignParameters
    }

    let id: String
    let title: String
    let group: Group
    let icon: String
    let call: Call
    /// Properties sent alongside the call, built from the current configuration,
    /// the randomised sample basket and the live push token.
    let properties: @MainActor (AppConfig, SampleBasket, String) -> [String: String]

    var callSignature: String {
        switch call {
        case .customEvent(let pageName): return "customEvent(\"\(pageName)\")"
        case .login(let extras): return extras ? "login(exVisitorId:properties:) + segments" : "login(exVisitorId:properties:)"
        case .signUp: return "signUp(exVisitorId:properties:)"
        case .logout: return "logout()"
        case .campaignParameters: return "sendCampaignParameters(properties:)"
        }
    }
}

enum AnalyticsCatalog {

    static let all: [AnalyticsAction] = [

        // MARK: Identity
        .init(id: "login", title: "Login", group: .identity, icon: "arrow.right.to.line",
              call: .login(withExtras: false)) { config, _, token in
            ["OM.sys.TokenID": token, "OM.sys.AppID": config.appAlias]
        },

        .init(id: "login-extras", title: "Login with extra parameters", group: .identity,
              icon: "person.badge.plus", call: .login(withExtras: true)) { config, basket, token in
            [
                "OM.sys.TokenID": token,
                "OM.sys.AppID": config.appAlias,
                "OM.vseg1": "seg1val",
                "OM.vseg2": "seg2val",
                "OM.vseg3": "seg3val",
                "OM.vseg4": "seg4val",
                "OM.vseg5": "seg5val",
                "OM.bd": "1977-03-15",
                "OM.gn": basket.gender,
                "OM.loc": "Bursa"
            ]
        },

        .init(id: "signup", title: "Sign up", group: .identity, icon: "person.fill.badge.plus",
              call: .signUp) { config, _, token in
            ["OM.sys.TokenID": token, "OM.sys.AppID": config.appAlias]
        },

        .init(id: "logout", title: "Logout", group: .identity, icon: "arrow.left.to.line",
              call: .logout) { _, _, _ in [:] },

        // MARK: Browsing
        .init(id: "page-view", title: "Page view", group: .browsing, icon: "doc.text.fill",
              call: .customEvent(pageName: "Page Name")) { _, _, _ in [:] },

        .init(id: "product-view", title: "Product view", group: .browsing, icon: "tag.fill",
              call: .customEvent(pageName: "Product View")) { _, basket, _ in
            [
                "OM.pv": basket.productCode1,
                "OM.pn": basket.productName1,
                "OM.ppr": basket.price1.priceString,
                "OM.pv.1": basket.brand,
                "OM.inv": "\(basket.inventory)"
            ]
        },

        .init(id: "category-view", title: "Category page view", group: .browsing,
              icon: "square.grid.3x3.fill",
              call: .customEvent(pageName: "Category View")) { _, basket, _ in
            ["OM.clist": "\(basket.categoryId)"]
        },

        .init(id: "search", title: "In-app search", group: .browsing, icon: "magnifyingglass",
              call: .customEvent(pageName: "In App Search")) { _, basket, _ in
            ["OM.OSS": basket.searchKeyword, "OM.OSSR": "\(basket.searchResultCount)"]
        },

        // MARK: Commerce
        .init(id: "add-to-cart", title: "Add to cart", group: .commerce, icon: "cart.badge.plus",
              call: .customEvent(pageName: "Cart")) { _, basket, _ in
            [
                "OM.pbid": "\(basket.basketId)",
                "OM.pb": "\(basket.productCode1);\(basket.productCode2)",
                "OM.pu": "\(basket.quantity1);\(basket.quantity2)",
                "OM.ppr": "\(basket.lineTotal1);\(basket.lineTotal2)"
            ]
        },

        .init(id: "purchase", title: "Purchase", group: .commerce, icon: "creditcard.fill",
              call: .customEvent(pageName: "Purchase")) { _, basket, _ in
            [
                "OM.tid": "\(basket.orderId)",
                "OM.pp": "\(basket.productCode1);\(basket.productCode2)",
                "OM.pu": "\(basket.quantity1);\(basket.quantity2)",
                "OM.ppr": "\(basket.lineTotal1);\(basket.lineTotal2)"
            ]
        },

        // MARK: Engagement
        .init(id: "add-favorite", title: "Add to favorites", group: .engagement, icon: "heart.fill",
              call: .customEvent(pageName: "Add To Favorites")) { _, basket, _ in
            ["OM.pf": basket.productCode1, "OM.pfu": "1", "OM.ppr": basket.price1.priceString]
        },

        .init(id: "remove-favorite", title: "Remove from favorites", group: .engagement,
              icon: "heart.slash.fill",
              call: .customEvent(pageName: "Add To Favorites")) { _, basket, _ in
            ["OM.pf": basket.productCode1, "OM.pfu": "-1", "OM.ppr": basket.price1.priceString]
        },

        .init(id: "banner-click", title: "Banner click", group: .engagement,
              icon: "rectangle.on.rectangle",
              call: .customEvent(pageName: "Banner Click")) { _, basket, _ in
            ["OM.OSB": "\(basket.bannerCode)"]
        },

        .init(id: "campaign", title: "Campaign parameters", group: .engagement,
              icon: "megaphone.fill", call: .campaignParameters) { _, _, _ in
            [
                "utm_source": "euromsg",
                "utm_medium": "push",
                "utm_campaign": "euromsg campaign",
                "OM.csource": "euromsg",
                "OM.cmedium": "push",
                "OM.cname": "euromsg campaign"
            ]
        },

        // MARK: System
        .init(id: "register-token", title: "Register push token", group: .system,
              icon: "key.fill",
              call: .customEvent(pageName: "RegisterToken")) { config, _, token in
            ["OM.sys.TokenID": token, "OM.sys.AppID": config.appAlias]
        }
    ]

    static func actions(in group: AnalyticsAction.Group) -> [AnalyticsAction] {
        all.filter { $0.group == group }
    }
}

// MARK: - Capture catalog

/// Rows of the Capture card. Each one calls the PostHog-compatible capture API.
enum CaptureTest: String, CaseIterable, Identifiable {
    case viewItem, addToCart, purchase, loginAndCapture, allPropertyTypes, setPersonProperties, batch, flush, logout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .viewItem: return "rmc_view_item"
        case .addToCart: return "rmc_add_to_cart"
        case .purchase: return "rmc_purchase (nested items)"
        case .loginAndCapture: return "Login + rmc_login"
        case .allPropertyTypes: return "All property types"
        case .setPersonProperties: return "Set person properties (email)"
        case .batch: return "25 events (batch)"
        case .flush: return "Flush queue"
        case .logout: return "Logout (new anonymous id)"
        }
    }

    var signature: String {
        switch self {
        case .viewItem, .addToCart, .purchase, .allPropertyTypes: return "capture(_:properties:)"
        case .loginAndCapture: return "login(exVisitorId:) → $identify, then capture"
        case .setPersonProperties: return "setPersonProperties(_:setOnce:) → $set"
        case .batch: return "sent at 20 events, the rest within 10 s"
        case .flush: return "flushCapture()"
        case .logout: return "logout() → reset capture identity"
        }
    }

    var icon: String {
        switch self {
        case .viewItem: return "eye.fill"
        case .addToCart: return "cart.badge.plus"
        case .purchase: return "creditcard.fill"
        case .loginAndCapture: return "person.crop.circle.badge.checkmark"
        case .allPropertyTypes: return "list.bullet.rectangle"
        case .setPersonProperties: return "person.text.rectangle"
        case .batch: return "square.stack.3d.up.fill"
        case .flush: return "paperplane.fill"
        case .logout: return "arrow.left.to.line"
        }
    }
}

// MARK: - View

struct EventsView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var push: PushCenter
    @EnvironmentObject private var toast: ToastCenter

    @State private var basket = SampleBasket.random()
    @State private var expanded: Set<String> = []
    @State private var captureDistinctId = ""
    @State private var captureAnonymousId = ""

    var body: some View {
        Screen(title: "Events",
               subtitle: "Each row performs a real SDK call. Expand a row to inspect its payload first.") {

            visitorCard

            ForEach(AnalyticsAction.Group.allCases) { group in
                Card(title: group.rawValue, systemImage: group.icon) {
                    let actions = AnalyticsCatalog.actions(in: group)
                    ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                        if index > 0 { RowDivider() }
                        row(for: action)
                    }
                }
            }

            captureCard

            Card(title: "Sample data", systemImage: "dice.fill",
                 footnote: "Product codes, prices and quantities are randomised so repeated sends stay distinguishable in the panel.") {
                InfoRow(label: "Products", value: "\(basket.productCode1), \(basket.productCode2)")
                RowDivider()
                InfoRow(label: "Prices", value: "\(basket.price1.priceString), \(basket.price2.priceString)")
                RowDivider()
                InfoRow(label: "Basket / order", value: "\(basket.basketId) / \(basket.orderId)")
                RowDivider()
                ActionRow(title: "Shuffle sample data", systemImage: "shuffle") {
                    basket = SampleBasket.random()
                    toast.show("New sample data generated", icon: "dice.fill", tint: Theme.info)
                }
            }
        }
    }

    // MARK: Visitor

    private var visitorCard: some View {
        Card(title: "Visitor", systemImage: "person.crop.circle.fill",
             footnote: "exVisitorId is required for login and signUp. Both values are persisted between launches.") {
            FieldRow(label: "exVisitorId", placeholder: "userKey", text: $config.exVisitorId)
            RowDivider()
            FieldRow(label: "email", placeholder: "user@mail.com",
                     text: $config.email, keyboard: .emailAddress)
            RowDivider()
            InfoRow(label: "Active exVisitorId", value: RelatedDigital.exVisitorId)
        }
    }

    // MARK: Rows

    @ViewBuilder
    private func row(for action: AnalyticsAction) -> some View {
        let isExpanded = expanded.contains(action.id)
        let properties = action.properties(config, basket, push.token)

        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.m) {
                Button {
                    send(action, properties: properties)
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: action.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 26, height: 26)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text(action.callSignature)
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded { expanded.remove(action.id) } else { expanded.insert(action.id) }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)

            if isExpanded {
                PayloadBlock(text: payloadPreview(for: action, properties: properties))
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.m)
            }
        }
    }

    private func payloadPreview(for action: AnalyticsAction, properties: [String: String]) -> String {
        var lines = [action.callSignature]
        if case .login = action.call { lines.append("exVisitorId = \(config.exVisitorId)") }
        if case .signUp = action.call { lines.append("exVisitorId = \(config.exVisitorId)") }
        if properties.isEmpty {
            lines.append("properties = [:]")
        } else {
            lines.append("properties:")
            lines.append(EventLog.render(properties))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Sending

    private func send(_ action: AnalyticsAction, properties: [String: String]) {
        switch action.call {
        case .customEvent(let pageName):
            RDLog.call("customEvent(\"\(pageName)\")", channel: .analytics, payload: properties)
            RelatedDigital.customEvent(pageName, properties: properties)
            toast.show("\(action.title) sent")

        case .login(let withExtras):
            guard requireVisitorId() else { return }
            RDLog.call("login(exVisitorId: \"\(config.exVisitorId)\")",
                       channel: .analytics, payload: properties)
            RelatedDigital.login(exVisitorId: config.exVisitorId, properties: properties)
            toast.show(withExtras ? "Login with segments sent" : "Login sent")

        case .signUp:
            guard requireVisitorId() else { return }
            RDLog.call("signUp(exVisitorId: \"\(config.exVisitorId)\")",
                       channel: .analytics, payload: properties)
            RelatedDigital.signUp(exVisitorId: config.exVisitorId, properties: properties)
            toast.show("Sign up sent")

        case .logout:
            RDLog.call("logout()", channel: .analytics)
            RelatedDigital.logout()
            toast.show("Logged out", icon: "arrow.left.to.line", tint: Theme.info)

        case .campaignParameters:
            RDLog.call("sendCampaignParameters()", channel: .analytics, payload: properties)
            RelatedDigital.sendCampaignParameters(properties: properties)
            toast.show("Campaign parameters sent")
        }

        // Sample values are single-use so consecutive sends differ.
        basket = SampleBasket.random()
        refreshCaptureIds()
    }

    // MARK: Capture

    private var captureCard: some View {
        Card(title: "Capture", systemImage: "chart.line.uptrend.xyaxis",
             footnote: "PostHog-compatible events, sent to event.visilabs.net in batches. Login and sign up identify the user with exVisitorId and merge the earlier anonymous events; logout starts a new anonymous id. With logging enabled the request bodies are printed to the Xcode console.") {
            InfoRow(label: "distinct_id", value: captureDistinctId)
            RowDivider()
            InfoRow(label: "anonymous_id", value: captureAnonymousId)
            RowDivider()
            InfoRow(label: "State",
                    value: captureDistinctId == captureAnonymousId ? "anonymous" : "identified",
                    isMonospaced: false)
            ForEach(CaptureTest.allCases) { test in
                RowDivider()
                ActionRow(title: test.title, subtitle: test.signature, systemImage: test.icon) {
                    runCaptureTest(test)
                }
            }
        }
        .onAppear(perform: refreshCaptureIds)
    }

    private func runCaptureTest(_ test: CaptureTest) {
        switch test {
        case .viewItem:
            capture("rmc_view_item", [
                "item_id": 1001,
                "item_name": "Shoei NXR2",
                "item_brand": "Shoei",
                "item_category": "Motor Kaskları",
                "item_variant": "Mat Siyah / L",
                "original_price": 2000,
                "discounted_price": 1500,
                "discount_rate": 20,
                "currency": "TRY",
                "cart_price": 1000,
                "product_rating": 4.8,
                "review_count": 126,
                "stock_quantity": 3,
                "stock_status": "low_stock",
                "list_source": "search",
                "search_term": "kask",
                "product_campaign": "Summer Sale"
            ])

        case .addToCart:
            capture("rmc_add_to_cart", [
                "item_id": 1001,
                "item_name": "Shoei NXR2",
                "quantity": 1,
                "price": 1500,
                "currency": "TRY",
                "cart_total": 2500
            ])

        case .purchase:
            capture("rmc_purchase", [
                "order_id": "ORD-\(basket.orderId)",
                "revenue": 2750.5,
                "currency": "TRY",
                "items": [
                    ["item_id": 1001, "quantity": 1, "price": 1500],
                    ["item_id": 2002, "quantity": 2, "price": 625.25]
                ] as [[String: Any]]
            ])

        case .loginAndCapture:
            guard requireVisitorId() else { return }
            // login sends $identify (anonymous id + exVisitorId are merged);
            // the rmc_login that follows already goes out with exVisitorId.
            RDLog.call("login(exVisitorId: \"\(config.exVisitorId)\")", channel: .analytics)
            RelatedDigital.login(exVisitorId: config.exVisitorId, properties: [:])
            capture("rmc_login", ["method": "email"])

        case .allPropertyTypes:
            capture("rmc_property_types", [
                "string": "text",
                "int": 42,
                "double": 3.14,
                "bool": true,
                "date": Date(),
                "url": URL(string: "https://www.relateddigital.com")!,
                "array": [1, "two", 3.0] as [Any],
                "dictionary": ["nested": true],
                "nan": Double.nan // dropped, the SDK logs a warning
            ])

        case .setPersonProperties:
            let email = config.email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !email.isEmpty else {
                toast.showError("email cannot be empty")
                return
            }
            RDLog.call("setPersonProperties", channel: .analytics,
                       payload: ["$set.email": email, "$set_once.first_seen_app": "RelatedDigitalExample"])
            RelatedDigital.setPersonProperties(["email": email], setOnce: ["first_seen_app": "RelatedDigitalExample"])
            toast.show("$set queued")

        case .batch:
            RDLog.call("capture × 25 (rmc_batch_test)", channel: .analytics)
            for index in 1...25 {
                RelatedDigital.capture("rmc_batch_test", properties: ["index": index])
            }
            toast.show("25 events queued")

        case .flush:
            RDLog.call("flushCapture()", channel: .analytics)
            RelatedDigital.flushCapture()
            toast.show("Capture queue flushed")

        case .logout:
            RDLog.call("logout()", channel: .analytics)
            RelatedDigital.logout()
            toast.show("Logged out", icon: "arrow.left.to.line", tint: Theme.info)
        }
        refreshCaptureIds()
    }

    private func capture(_ event: String, _ properties: [String: Any]) {
        RDLog.call("capture(\"\(event)\")", channel: .analytics,
                   payload: properties.mapValues { "\($0)" })
        RelatedDigital.capture(event, properties: properties)
        toast.show("\(event) queued")
    }

    private func refreshCaptureIds() {
        captureDistinctId = RelatedDigital.getDistinctId()
        captureAnonymousId = RelatedDigital.getAnonymousId()
    }

    private func requireVisitorId() -> Bool {
        let trimmed = config.exVisitorId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toast.showError("exVisitorId cannot be empty")
            RDLog.failure("Call skipped — exVisitorId is empty", channel: .analytics)
            return false
        }
        config.exVisitorId = trimmed
        return true
    }
}
