//
//  ConsoleView.swift
//  RelatedDigitalExample
//
//  On-device record of every SDK call and callback. Replaces reading Xcode's
//  console, which is not an option when testing on a real device in the field.
//

import SwiftUI

struct ConsoleView: View {

    @EnvironmentObject private var log: EventLog
    @EnvironmentObject private var toast: ToastCenter

    @State private var query = ""
    @State private var channelFilter: LogEntry.Channel?
    @State private var kindFilter: LogEntry.Kind?
    @State private var expanded: Set<UUID> = []

    private var entries: [LogEntry] {
        let needle = query.trimmed.lowercased()
        return log.entries.filter { entry in
            if let channelFilter, entry.channel != channelFilter { return false }
            if let kindFilter, entry.kind != kindFilter { return false }
            guard !needle.isEmpty else { return true }
            return entry.title.lowercased().contains(needle)
                || (entry.detail?.lowercased().contains(needle) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar

            if entries.isEmpty {
                Spacer()
                EmptyState(systemImage: "terminal",
                           title: log.entries.isEmpty ? "Console is empty" : "No matching entry",
                           message: log.entries.isEmpty
                                ? "Trigger an event, a targeting action or a push call and it will show up here."
                                : "Adjust the filters or clear the search text.")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.s) {
                        ForEach(entries) { entry in
                            row(entry)
                        }
                    }
                    .padding(Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Console")
        .searchable(text: $query, prompt: "Search console")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        UIPasteboard.general.string = log.exportText
                        toast.show("Console copied")
                    } label: {
                        Label("Copy all", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        log.clear()
                        expanded.removeAll()
                        toast.show("Console cleared", icon: "trash.fill", tint: Theme.danger)
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Filters

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                filterChip(title: "All", isOn: channelFilter == nil && kindFilter == nil) {
                    channelFilter = nil
                    kindFilter = nil
                }

                ForEach(LogEntry.Kind.allCases, id: \.self) { kind in
                    filterChip(title: kind.rawValue.capitalized,
                               tint: kind.tint,
                               isOn: kindFilter == kind) {
                        kindFilter = kindFilter == kind ? nil : kind
                    }
                }

                Divider().frame(height: 20)

                ForEach(LogEntry.Channel.allCases) { channel in
                    filterChip(title: channel.rawValue,
                               icon: channel.icon,
                               isOn: channelFilter == channel) {
                        channelFilter = channelFilter == channel ? nil : channel
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.m)
        }
        .background(Theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    private func filterChip(title: String,
                            icon: String? = nil,
                            tint: Color = Theme.accent,
                            isOn: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 10, weight: .bold))
                }
                Text(title).font(.caption.weight(.medium))
            }
            .foregroundStyle(isOn ? .white : tint)
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, 7)
            .background(isOn ? tint : tint.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rows

    private func row(_ entry: LogEntry) -> some View {
        let isExpanded = expanded.contains(entry.id)
        let hasDetail = !(entry.detail ?? "").isEmpty

        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: entry.kind.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(entry.kind.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(entry.timestamp)
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.textTertiary)
                        Pill(text: entry.channel.rawValue, tint: entry.kind.tint,
                             systemImage: entry.channel.icon)
                    }
                }

                Spacer(minLength: 0)

                if hasDetail {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            if isExpanded, let detail = entry.detail {
                PayloadBlock(text: detail, maxHeight: 260)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard hasDetail else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded { expanded.remove(entry.id) } else { expanded.insert(entry.id) }
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = entry.plainText
                toast.show("Entry copied")
            } label: {
                Label("Copy entry", systemImage: "doc.on.doc")
            }
        }
    }
}
