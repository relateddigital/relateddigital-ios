//
//  FavoriteAttributesView.swift
//  RelatedDigitalExample
//
//  Runs `getFavoriteAttributeActions` and renders the returned attribute groups
//  instead of dumping them to the debugger.
//

import RelatedDigitalIOS
import SwiftUI

struct FavoriteAttributesView: View {

    @EnvironmentObject private var toast: ToastCenter

    @State private var actionId = ""
    @State private var groups: [Group] = []
    @State private var isRunning = false
    @State private var hasRun = false

    struct Group: Identifiable {
        let id = UUID()
        let attribute: String
        let values: [String]
    }

    var body: some View {
        Screen(title: "Favorite attributes",
               subtitle: "RelatedDigital.getFavoriteAttributeActions(actionId:)") {

            Card(title: "Query", systemImage: "slider.horizontal.3",
                 footnote: "Leave the action id empty to fetch every favorite-attribute action defined on the profile.") {
                FieldRow(label: "Action id", placeholder: "optional", text: $actionId, keyboard: .numberPad)
            }

            PrimaryButton(title: "Fetch favorite attributes",
                          systemImage: "heart.fill",
                          isLoading: isRunning) {
                run()
            }

            if hasRun {
                if groups.isEmpty {
                    Card {
                        EmptyState(systemImage: "heart.slash",
                                   title: "No favorites returned",
                                   message: "The profile has no favorite-attribute action matching this query.")
                    }
                } else {
                    ForEach(groups) { group in
                        Card(title: group.attribute, systemImage: "heart.fill",
                             footnote: "\(group.values.count) value(s)") {
                            ForEach(Array(group.values.enumerated()), id: \.offset) { index, value in
                                if index > 0 { RowDivider() }
                                Text(value)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Theme.Spacing.l)
                                    .padding(.vertical, Theme.Spacing.m)
                            }
                        }
                    }
                }
            }
        }
    }

    private func run() {
        let id = Int(actionId.trimmed)
        isRunning = true
        RDLog.call("getFavoriteAttributeActions(actionId:)", channel: .targeting,
                   payload: ["actionId": id.map(String.init) ?? "nil"])

        RelatedDigital.getFavoriteAttributeActions(actionId: id) { response in
            Task { @MainActor in
                isRunning = false
                hasRun = true

                if let error = response.error {
                    groups = []
                    RDLog.failure("getFavoriteAttributeActions failed", channel: .targeting,
                                  detail: String(describing: error))
                    toast.showError("Request failed")
                    return
                }

                groups = response.favorites
                    .filter { !$0.value.isEmpty }
                    .sorted { $0.key.rawValue < $1.key.rawValue }
                    .map { Group(attribute: $0.key.rawValue, values: $0.value) }

                let total = groups.reduce(0) { $0 + $1.values.count }
                RDLog.result("getFavoriteAttributeActions → \(groups.count) group(s), \(total) value(s)",
                             channel: .targeting,
                             detail: groups.isEmpty ? nil : groups
                                .map { "\($0.attribute): \($0.values.joined(separator: ", "))" }
                                .joined(separator: "\n"))
                toast.show(groups.isEmpty ? "No favorites returned" : "\(total) value(s) returned")
            }
        }
    }
}
