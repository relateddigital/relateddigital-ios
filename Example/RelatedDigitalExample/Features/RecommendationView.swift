//
//  RecommendationView.swift
//  RelatedDigitalExample
//
//  Recommendation zone runner with a working filter builder and rendered
//  results — tapping a product reports the click back through the SDK.
//

import RelatedDigitalIOS
import SwiftUI

struct RecommendationView: View {

    @EnvironmentObject private var toast: ToastCenter

    @State private var zoneId = "1"
    @State private var productCode = ""
    @State private var filters: [FilterDraft] = [
        FilterDraft(attribute: .PRODUCTNAME, type: .like, value: "a")
    ]
    @State private var products: [RDProduct] = []
    @State private var widgetTitle = ""
    @State private var isRunning = false
    @State private var hasRun = false

    var body: some View {
        Screen(title: "Recommendation",
               subtitle: "RelatedDigital.recommend(zoneId:productCode:filters:properties:)") {

            Card(title: "Zone", systemImage: "target",
                 footnote: "Product code is optional and only used by zones configured for product-based recommendations.") {
                FieldRow(label: "Zone id", placeholder: "1", text: $zoneId, keyboard: .numberPad)
                RowDivider()
                FieldRow(label: "Product code", placeholder: "optional", text: $productCode)
            }

            filtersCard

            PrimaryButton(title: "Run recommendation",
                          systemImage: "play.fill",
                          isLoading: isRunning) {
                run()
            }

            resultsCard
        }
    }

    // MARK: - Filters

    private var filtersCard: some View {
        Card(title: "Filters", systemImage: "line.3.horizontal.decrease.circle.fill",
             footnote: "Multiple values for one attribute can be comma separated, e.g. code1,code2,code3.") {
            if filters.isEmpty {
                EmptyState(systemImage: "line.3.horizontal.decrease",
                           title: "No filters",
                           message: "The zone will be queried without any product filter.")
            } else {
                ForEach($filters) { $filter in
                    filterEditor($filter)
                    RowDivider()
                }
            }

            ActionRow(title: "Add filter", systemImage: "plus.circle.fill") {
                filters.append(FilterDraft(attribute: .PRODUCTCODE, type: .equals, value: ""))
            }
        }
    }

    private func filterEditor(_ filter: Binding<FilterDraft>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Picker("Attribute", selection: filter.attribute) {
                    ForEach(FilterDraft.attributes, id: \.self) { attribute in
                        Text(FilterDraft.label(for: attribute)).tag(attribute)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .lineLimit(1)

                Picker("Type", selection: filter.type) {
                    ForEach(FilterDraft.types, id: \.self) { type in
                        Text(FilterDraft.label(for: type)).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .fixedSize()

                Spacer(minLength: 0)

                Button {
                    filters.removeAll { $0.id == filter.wrappedValue.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Theme.danger)
                }
                .buttonStyle(.plain)
            }

            TextField("value", text: filter.value)
                .font(Theme.mono(12))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(Theme.Spacing.s)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsCard: some View {
        if hasRun {
            Card(title: widgetTitle.isEmpty ? "Results" : widgetTitle,
                 systemImage: "shippingbox.fill",
                 footnote: products.isEmpty ? nil : "Tap a product to report the click via trackRecommendationClick(qs:).") {
                if products.isEmpty {
                    EmptyState(systemImage: "shippingbox",
                               title: "No products returned",
                               message: "The zone matched nothing for these filters. Check the Console tab for the raw outcome.")
                } else {
                    ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                        if index > 0 { RowDivider() }
                        Button { trackClick(product) } label: { productRow(product) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func productRow(_ product: RDProduct) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            AsyncImage(url: URL(string: product.img)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 56, height: 56)
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.title.isEmpty ? product.code : product.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(product.code)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.textTertiary)
                HStack(spacing: 6) {
                    Text("\(product.price.priceString) \(product.cur)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if product.discount > 0 {
                        Pill(text: "-\(Int(product.discount))%", tint: Theme.danger)
                    }
                    if !product.brand.isEmpty {
                        Pill(text: product.brand, tint: Theme.info)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "hand.tap.fill")
                .font(.caption)
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func run() {
        let zone = zoneId.trimmed
        guard !zone.isEmpty else {
            toast.showError("Zone id is required")
            return
        }

        let sdkFilters = filters
            .filter { !$0.value.trimmed.isEmpty }
            .map { RDRecommendationFilter(attribute: $0.attribute, filterType: $0.type, value: $0.value.trimmed) }

        let payload = filters.reduce(into: ["zoneId": zone, "productCode": productCode]) { result, filter in
            guard !filter.value.trimmed.isEmpty else { return }
            result[filter.attribute.rawValue] = "\(FilterDraft.label(for: filter.type)) \(filter.value.trimmed)"
        }

        isRunning = true
        RDLog.call("recommend(zoneId:)", channel: .recommendation, payload: payload)

        RelatedDigital.recommend(zoneId: zone,
                                 productCode: productCode.trimmed,
                                 filters: sdkFilters,
                                 properties: [:]) { response in
            Task { @MainActor in
                isRunning = false
                hasRun = true

                if let error = response.error {
                    products = []
                    widgetTitle = ""
                    RDLog.failure("recommend failed", channel: .recommendation,
                                  detail: String(describing: error))
                    toast.showError("Recommendation failed")
                    return
                }

                products = response.products
                widgetTitle = response.widgetTitle
                RDLog.result("recommend → \(response.products.count) product(s)",
                             channel: .recommendation,
                             detail: response.products.isEmpty
                                ? "widgetTitle = \(response.widgetTitle)"
                                : response.products
                                    .map { "\($0.code) · \($0.title) · \($0.price.priceString) \($0.cur)" }
                                    .joined(separator: "\n"))
                toast.show("\(response.products.count) product(s) returned")
            }
        }
    }

    private func trackClick(_ product: RDProduct) {
        RDLog.call("trackRecommendationClick(qs:)", channel: .recommendation,
                   payload: ["code": product.code, "qs": product.qs])
        RelatedDigital.trackRecommendationClick(qs: product.qs)
        toast.show("Click reported for \(product.code)")
    }
}

// MARK: - Filter draft

struct FilterDraft: Identifiable {
    let id = UUID()
    var attribute: RDProductFilterAttribute
    var type: RDRecommendationFilterType
    var value: String

    static let attributes: [RDProductFilterAttribute] = [
        .PRODUCTNAME, .PRODUCTCODE, .BRAND, .CATEGORYCODE, .COLOR, .GENDER,
        .AGEGROUP, .MATERIAL, .ATTRIBUTE1, .ATTRIBUTE2, .ATTRIBUTE3,
        .ATTRIBUTE4, .ATTRIBUTE5, .FREESHIPPING, .SHIPPINGONSAMEDAY, .ISDISCOUNTED
    ]

    static let types: [RDRecommendationFilterType] = [
        .equals, .notEquals, .like, .notLike,
        .greaterThan, .lessThan, .greaterOrEquals, .lessOrEquals
    ]

    /// Panel field names are shouty constants; show something readable instead.
    static func label(for attribute: RDProductFilterAttribute) -> String {
        switch attribute {
        case .PRODUCTNAME: return "Name"
        case .PRODUCTCODE: return "Code"
        case .BRAND: return "Brand"
        case .CATEGORYCODE: return "Category"
        case .COLOR: return "Color"
        case .GENDER: return "Gender"
        case .AGEGROUP: return "Age group"
        case .MATERIAL: return "Material"
        case .ATTRIBUTE1: return "Attr 1"
        case .ATTRIBUTE2: return "Attr 2"
        case .ATTRIBUTE3: return "Attr 3"
        case .ATTRIBUTE4: return "Attr 4"
        case .ATTRIBUTE5: return "Attr 5"
        case .FREESHIPPING: return "Free shipping"
        case .SHIPPINGONSAMEDAY: return "Same-day shipping"
        case .ISDISCOUNTED: return "Discounted"
        }
    }

    static func label(for type: RDRecommendationFilterType) -> String {
        switch type {
        case .equals: return "="
        case .notEquals: return "≠"
        case .like: return "like"
        case .notLike: return "not like"
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterOrEquals: return "≥"
        case .lessOrEquals: return "≤"
        }
    }
}
