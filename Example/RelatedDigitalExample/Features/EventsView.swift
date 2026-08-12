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

// MARK: - View

struct EventsView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var push: PushCenter
    @EnvironmentObject private var toast: ToastCenter

    @State private var basket = SampleBasket.random()
    @State private var expanded: Set<String> = []

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
