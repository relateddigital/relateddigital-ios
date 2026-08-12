//
//  RootView.swift
//  RelatedDigitalExample
//
//  Five tabs cover the SDK surface: overview, analytics events, targeting
//  actions, push, and the console that records every call.
//

import SwiftUI

struct RootView: View {

    enum Tab: Hashable {
        case dashboard, events, targeting, push, console
    }

    @State private var selection: Tab = .dashboard
    @EnvironmentObject private var log: EventLog

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { DashboardView() }
                .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.dashboard)

            NavigationStack { EventsView() }
                .tabItem { Label("Events", systemImage: "chart.bar.fill") }
                .tag(Tab.events)

            NavigationStack { TargetingActionsView() }
                .tabItem { Label("Targeting", systemImage: "sparkles") }
                .tag(Tab.targeting)

            NavigationStack { PushView() }
                .tabItem { Label("Push", systemImage: "bell.badge.fill") }
                .tag(Tab.push)

            NavigationStack { ConsoleView() }
                .tabItem { Label("Console", systemImage: "terminal.fill") }
                .badge(log.entries.count)
                .tag(Tab.console)
        }
    }
}
