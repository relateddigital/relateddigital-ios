//
//  EmbeddedWidgetsView.swift
//  RelatedDigitalExample
//
//  Targeting surfaces that are embedded into the host layout instead of being
//  presented over it: the story rail, banner carousel, button carousel and the
//  standalone NPS view.
//

import RelatedDigitalIOS
import SwiftUI
import UIKit

// MARK: - View model

@MainActor
final class EmbeddedWidgetsModel: ObservableObject {

    @Published var storyView: UIView?
    @Published var bannerView: UIView?
    @Published var buttonCarouselView: UIView?
    @Published var npsView: UIView?
    @Published var loading: Set<String> = []

    private lazy var delegates = WidgetDelegates(model: self)

    // MARK: Story

    func loadStory(actionId: String) {
        let id = Int(actionId.trimmed)
        begin("story")
        RDLog.call("getStoryViewAsync(actionId:)", channel: .targeting,
                   payload: ["actionId": id.map(String.init) ?? "nil"])

        RelatedDigital.getStoryViewAsync(actionId: id) { [weak self] view in
            Task { @MainActor in
                guard let self else { return }
                self.end("story")
                guard let view else {
                    self.storyView = nil
                    RDLog.failure("No story action matched the criteria", channel: .targeting)
                    return
                }
                view.controller?.urlDelegate = TargetingDelegateHub.shared
                self.storyView = view
                RDLog.result("Story view loaded", channel: .targeting)
            }
        }
    }

    // MARK: Banner carousel

    func loadBanner() {
        begin("banner")
        let properties: Properties = ["OM.inapptype": "banner_carousel"]
        RDLog.call("getBannerView(properties:)", channel: .targeting, payload: properties)

        RelatedDigital.getBannerView(properties: properties) { [weak self] banner in
            Task { @MainActor in
                guard let self else { return }
                self.end("banner")
                guard let banner else {
                    self.bannerView = nil
                    RDLog.failure("No banner action matched the criteria", channel: .targeting)
                    return
                }
                banner.delegate = self.delegates
                banner.reloadBannerViewData()
                self.bannerView = banner
                RDLog.result("Banner carousel loaded", channel: .targeting)
            }
        }
    }

    // MARK: Button carousel

    func loadButtonCarousel() {
        begin("buttons")
        let properties: Properties = ["OM.inapptype": "button_carousel"]
        RDLog.call("getButtonCarouselView(properties:)", channel: .targeting, payload: properties)

        RelatedDigital.getButtonCarouselView(properties: properties) { [weak self] carousel in
            Task { @MainActor in
                guard let self else { return }
                self.end("buttons")
                guard let carousel else {
                    self.buttonCarouselView = nil
                    RDLog.failure("No button carousel action matched the criteria", channel: .targeting)
                    return
                }
                carousel.delegate = self.delegates
                self.buttonCarouselView = carousel
                RDLog.result("Button carousel loaded", channel: .targeting)
            }
        }
    }

    // MARK: NPS

    func loadNps() {
        begin("nps")
        let properties: Properties = ["OM.inapptype": "nps_with_numbers"]
        RDLog.call("getNpsWithNumbersView(properties:delegate:)", channel: .targeting, payload: properties)

        RelatedDigital.getNpsWithNumbersView(properties: properties, delegate: delegates) { [weak self] view in
            Task { @MainActor in
                guard let self else { return }
                self.end("nps")
                guard let view else {
                    self.npsView = nil
                    RDLog.failure("No NPS action matched the criteria", channel: .targeting)
                    return
                }
                self.npsView = view
                RDLog.result("NPS view loaded", channel: .targeting)
            }
        }
    }

    func dismissNps() { npsView = nil }

    // MARK: Loading state

    func isLoading(_ key: String) -> Bool { loading.contains(key) }
    private func begin(_ key: String) { loading.insert(key) }
    private func end(_ key: String) { loading.remove(key) }
}

/// Non-isolated delegate target: the SDK invokes these from arbitrary queues.
private final class WidgetDelegates: NSObject {
    private weak var model: EmbeddedWidgetsModel?
    init(model: EmbeddedWidgetsModel) { self.model = model }
}

extension WidgetDelegates: BannerDelegate {
    func bannerItemClickListener(url: String) {
        Task { @MainActor in
            RDLog.result("Banner item tapped", channel: .targeting, detail: url)
        }
    }
}

extension WidgetDelegates: ButtonCarouselViewDelegate {}

extension WidgetDelegates: RDNpsWithNumbersDelegate {
    func npsItemClicked(npsLink: String?) {
        Task { @MainActor in
            RDLog.result("NPS item tapped", channel: .targeting, detail: npsLink ?? "no link")
            self.model?.dismissNps()
        }
    }
}

// MARK: - View

struct EmbeddedWidgetsView: View {

    @StateObject private var model = EmbeddedWidgetsModel()
    @EnvironmentObject private var toast: ToastCenter

    @State private var storyActionId = "305"

    var body: some View {
        Screen(title: "Embedded widgets",
               subtitle: "Views returned by the SDK, hosted inside SwiftUI.") {

            Card(title: "Story rail", systemImage: "circle.grid.3x3.fill",
                 footnote: "Leave the action id empty to let the SDK pick the first matching story action.") {
                FieldRow(label: "Action id", placeholder: "optional",
                         text: $storyActionId, keyboard: .numberPad)
                RowDivider()
                ActionRow(title: "Load story rail",
                          subtitle: "getStoryViewAsync(actionId:)",
                          systemImage: model.isLoading("story") ? "hourglass" : "play.circle.fill") {
                    model.loadStory(actionId: storyActionId)
                }
                if let view = model.storyView {
                    RowDivider()
                    HostedUIView(view: view)
                        .frame(height: 150)
                        .padding(.vertical, Theme.Spacing.s)
                }
            }

            Card(title: "Banner carousel", systemImage: "rectangle.on.rectangle",
                 footnote: "OM.inapptype = banner_carousel") {
                ActionRow(title: "Load banner carousel",
                          subtitle: "getBannerView(properties:)",
                          systemImage: model.isLoading("banner") ? "hourglass" : "play.circle.fill") {
                    model.loadBanner()
                }
                if let view = model.bannerView {
                    RowDivider()
                    HostedUIView(view: view)
                        .frame(height: 90)
                        .padding(.vertical, Theme.Spacing.s)
                }
            }

            Card(title: "Button carousel", systemImage: "square.grid.3x1.below.line.grid.1x2",
                 footnote: "OM.inapptype = button_carousel") {
                ActionRow(title: "Load button carousel",
                          subtitle: "getButtonCarouselView(properties:)",
                          systemImage: model.isLoading("buttons") ? "hourglass" : "play.circle.fill") {
                    model.loadButtonCarousel()
                }
                if let view = model.buttonCarouselView {
                    RowDivider()
                    HostedUIView(view: view)
                        .frame(height: 90)
                        .padding(.vertical, Theme.Spacing.s)
                }
            }

            Card(title: "NPS with numbers", systemImage: "number.square.fill",
                 footnote: "OM.inapptype = nps_with_numbers · the view removes itself once a score is tapped.") {
                ActionRow(title: "Load NPS view",
                          subtitle: "getNpsWithNumbersView(properties:delegate:)",
                          systemImage: model.isLoading("nps") ? "hourglass" : "play.circle.fill") {
                    model.loadNps()
                }
                if let view = model.npsView {
                    RowDivider()
                    HostedUIView(view: view)
                        .frame(height: 520)
                        .padding(.vertical, Theme.Spacing.s)
                    RowDivider()
                    ActionRow(title: "Dismiss", systemImage: "xmark.circle.fill", tint: Theme.danger) {
                        model.dismissNps()
                    }
                }
            }

            Note("Results land in the Console tab: loaded / not-matched outcomes as well as every tap forwarded through the widget delegates.")
        }
    }
}
