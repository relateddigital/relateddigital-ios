//
//  TargetingActionsView.swift
//  RelatedDigitalExample
//
//  Triggers targeting actions. Everything here funnels through the same
//  mechanism the SDK expects: a custom event carrying `OM.inapptype`.
//

import RelatedDigitalIOS
import SwiftUI

// MARK: - Catalog

/// A targeting action configured on the demo profile.
struct TargetingAction: Identifiable, Hashable {

    enum Category: String, CaseIterable, Identifiable {
        case popups = "Popups"
        case surveys = "Surveys & NPS"
        case forms = "Forms"
        case gamification = "Gamification"
        case inline = "Inline & widgets"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .popups: return "rectangle.portrait.on.rectangle.portrait.fill"
            case .surveys: return "list.bullet.clipboard.fill"
            case .forms: return "envelope.fill"
            case .gamification: return "gamecontroller.fill"
            case .inline: return "rectangle.3.group.fill"
            }
        }
    }

    /// Value sent as `OM.inapptype`.
    let queryString: String
    /// Action id in the Related Digital panel, for cross-checking.
    let actionId: Int
    let category: Category
    /// Extra properties some action types require on top of `OM.inapptype`.
    var extraProperties: [String: String] = [:]

    var id: String { "\(queryString)-\(actionId)" }

    var title: String {
        queryString
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

enum TargetingCatalog {

    static let all: [TargetingAction] = [
        // Popups
        .init(queryString: RDInAppNotificationType.mini.rawValue, actionId: 491, category: .popups),
        .init(queryString: RDInAppNotificationType.full.rawValue, actionId: 485, category: .popups),
        .init(queryString: RDInAppNotificationType.fullImage.rawValue, actionId: 495, category: .popups),
        .init(queryString: RDInAppNotificationType.imageButton.rawValue, actionId: 489, category: .popups),
        .init(queryString: RDInAppNotificationType.imageTextButton.rawValue, actionId: 490, category: .popups),
        .init(queryString: RDInAppNotificationType.halfScreenImage.rawValue, actionId: 704, category: .popups),
        .init(queryString: RDInAppNotificationType.downHsView.rawValue, actionId: 238, category: .popups),
        .init(queryString: RDInAppNotificationType.drawer.rawValue, actionId: 884, category: .popups),
        .init(queryString: RDInAppNotificationType.video.rawValue, actionId: 73, category: .popups),
        .init(queryString: "alert_actionsheet", actionId: 487, category: .popups),
        .init(queryString: "alert_native", actionId: 540, category: .popups),
        .init(queryString: RDInAppNotificationType.inappcarousel.rawValue, actionId: 927, category: .popups),
        .init(queryString: "fullscreen_carousel", actionId: 1349, category: .popups),
        .init(queryString: "fullscreen_popup", actionId: 1457, category: .popups),
        .init(queryString: RDInAppNotificationType.mobileCustomActions.rawValue, actionId: 1100, category: .popups),
        .init(queryString: RDInAppNotificationType.apprating.rawValue, actionId: 1101, category: .popups),

        // Surveys & NPS
        .init(queryString: RDInAppNotificationType.nps.rawValue, actionId: 492, category: .surveys),
        .init(queryString: RDInAppNotificationType.npsWithNumbers.rawValue, actionId: 493, category: .surveys),
        .init(queryString: RDInAppNotificationType.smileRating.rawValue, actionId: 494, category: .surveys),
        .init(queryString: "nps-image-text-button", actionId: 585, category: .surveys),
        .init(queryString: "nps-image-text-button-image", actionId: 586, category: .surveys),
        .init(queryString: "nps-feedback", actionId: 587, category: .surveys),
        .init(queryString: RDInAppNotificationType.npsWithMultiplePopup.rawValue, actionId: 1438, category: .surveys),
        .init(queryString: RDInAppNotificationType.MultipleChoiceSurvey.rawValue, actionId: 3111, category: .surveys),

        // Forms
        .init(queryString: RDInAppNotificationType.emailForm.rawValue, actionId: 417, category: .forms),

        // Gamification
        .init(queryString: RDInAppNotificationType.scratchToWin.rawValue, actionId: 592, category: .gamification),
        .init(queryString: RDInAppNotificationType.spintowin.rawValue, actionId: 562, category: .gamification),
        .init(queryString: RDInAppNotificationType.gamification.rawValue, actionId: 131, category: .gamification),
        .init(queryString: RDInAppNotificationType.findToWin.rawValue, actionId: 132, category: .gamification),
        .init(queryString: RDInAppNotificationType.shakeToWin.rawValue, actionId: 255, category: .gamification),
        .init(queryString: RDInAppNotificationType.giftBox.rawValue, actionId: 577, category: .gamification),
        .init(queryString: RDInAppNotificationType.choosefavorite.rawValue, actionId: 1098, category: .gamification),
        .init(queryString: RDInAppNotificationType.slotMachine.rawValue, actionId: 1099, category: .gamification),
        .init(queryString: RDInAppNotificationType.clawMachine.rawValue, actionId: 1111, category: .gamification),

        // Inline & widgets
        .init(queryString: RDInAppNotificationType.notificationBell.rawValue, actionId: 4321, category: .inline),
        .init(queryString: RDInAppNotificationType.CountdownTimerBanner.rawValue, actionId: 75759, category: .inline),
        .init(queryString: RDInAppNotificationType.productStatNotifier.rawValue, actionId: 703, category: .inline,
              extraProperties: ["OM.pv": "CV7933-837-837"])
    ]
}

// MARK: - View

struct TargetingActionsView: View {

    @EnvironmentObject private var config: AppConfig
    @EnvironmentObject private var toast: ToastCenter

    @State private var query = ""
    @State private var customQueryString = ""

    private var filtered: [TargetingAction] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return TargetingCatalog.all }
        return TargetingCatalog.all.filter {
            $0.queryString.lowercased().contains(needle) || "\($0.actionId)".contains(needle)
        }
    }

    var body: some View {
        Screen(title: "Targeting",
               subtitle: "Fires customEvent(\"InAppTest\") with OM.inapptype set to the selected action.") {

            if !config.inAppNotificationsEnabled {
                disabledBanner
            }

            customTriggerCard

            ForEach(TargetingAction.Category.allCases) { category in
                let actions = filtered.filter { $0.category == category }
                if !actions.isEmpty {
                    Card(title: category.rawValue, systemImage: category.icon) {
                        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                            if index > 0 { RowDivider() }
                            ActionRow(title: action.title,
                                      subtitle: "OM.inapptype = \(action.queryString)  ·  ID \(action.actionId)",
                                      systemImage: category.icon) {
                                trigger(action)
                            }
                        }
                    }
                }
            }

            if filtered.isEmpty {
                Card {
                    EmptyState(systemImage: "magnifyingglass",
                               title: "No matching action",
                               message: "No configured action matches “\(query)”. Use the custom trigger above to fire an arbitrary OM.inapptype value.")
                }
            }

            Note("Banner carousel, button carousel, story rail and the standalone NPS view are embedded views rather than popups — they live under Overview → Embedded widgets.")
        }
        .searchable(text: $query, prompt: "Search action or ID")
    }

    // MARK: Cards

    private var disabledBanner: some View {
        Banner(title: "In-app notifications are off",
               message: "Events will still be sent, but nothing will be displayed. Turn the module back on from Overview → Modules.",
               systemImage: "exclamationmark.triangle.fill",
               tint: Theme.warning)
    }

    private var customTriggerCard: some View {
        Card(title: "Custom trigger", systemImage: "slider.horizontal.3",
             footnote: "Use this to test an action that is not in the catalog yet — the value goes straight into OM.inapptype.") {
            FieldRow(label: "OM.inapptype", placeholder: "my_new_action", text: $customQueryString)
            RowDivider()
            ActionRow(title: "Fire custom action",
                      subtitle: "customEvent(\"InAppTest\")",
                      systemImage: "paperplane.fill",
                      isEnabled: !customQueryString.trimmingCharacters(in: .whitespaces).isEmpty) {
                let value = customQueryString.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { return }
                send(queryString: value, extra: [:], title: value)
            }
        }
    }

    // MARK: Triggering

    private func trigger(_ action: TargetingAction) {
        send(queryString: action.queryString, extra: action.extraProperties, title: action.title)
    }

    private func send(queryString: String, extra: [String: String], title: String) {
        var properties = extra
        properties["OM.inapptype"] = queryString

        RDLog.call("customEvent(\"InAppTest\")", channel: .targeting, payload: properties)
        RelatedDigital.customEvent("InAppTest", properties: properties)
        toast.show("\(title) triggered", icon: "sparkles", tint: Theme.accent)
    }
}
