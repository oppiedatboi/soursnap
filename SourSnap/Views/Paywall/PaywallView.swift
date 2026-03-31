import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPlan: PlanOption = .yearly
    @State private var appeared = false
    @State private var isPurchasing = false

    private let storeManager = StoreManager.shared

    enum PlanOption {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        comparisonCard
                        planSelector
                        purchaseButton
                        restoreButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }

                if isPurchasing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    SwiftUI.ProgressView("Processing...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .tint(Color.appPrimary)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .task {
                await storeManager.loadProducts()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 14) {
            BubMascot(pose: .celebrating, size: 140)
                .scaleEffect(appeared ? 1.0 : 0.7)
                .opacity(appeared ? 1 : 0)

            Text("Unlock the Full Kibo Experience")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text("Your starter deserves unlimited attention")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 60)
                Text("Pro")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appSurface)

            Divider().foregroundStyle(Color.appBorder)

            comparisonRow(feature: "Journal Entries", free: "3", pro: "Unlimited")
            comparisonRow(feature: "Daily Chats", free: "5", pro: "Unlimited")
            comparisonRow(feature: "AI Analysis", free: "Basic", pro: "Detailed")
            comparisonRow(feature: "Feeding Reminders", free: true, pro: true)
            comparisonRow(feature: "Progress Timeline", free: false, pro: true)
            comparisonRow(feature: "Export Data", free: false, pro: true)
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func comparisonRow(feature: String, free: String, pro: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(free)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 60)
                Text(pro)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().foregroundStyle(Color.appBorder)
        }
    }

    private func comparisonRow(feature: String, free: Bool, pro: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: free ? "checkmark.circle.fill" : "minus.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(free ? Color.appSuccess : Color.appTextSecondary.opacity(0.4))
                    .frame(width: 60)
                Image(systemName: pro ? "checkmark.circle.fill" : "minus.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(pro ? Color.appSuccess : Color.appTextSecondary.opacity(0.4))
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().foregroundStyle(Color.appBorder)
        }
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        VStack(spacing: 12) {
            // Yearly plan
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: storeManager.yearlyProduct?.displayPrice ?? "$49.99",
                subtitle: "$4.17/month",
                badge: "Save 17%"
            )

            // Monthly plan
            planCard(
                plan: .monthly,
                title: "Monthly",
                price: storeManager.monthlyProduct?.displayPrice ?? "$4.99",
                subtitle: "per month",
                badge: nil
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func planCard(plan: PlanOption, title: String, price: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                // Radio indicator
                Circle()
                    .strokeBorder(isSelected ? Color.appPrimary : Color.appBorder, lineWidth: isSelected ? 6 : 2)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.appSuccess, in: Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                Text(price)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }
            .padding(16)
            .background(
                isSelected ? Color.appPrimary.opacity(0.08) : Color.appSurface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.appPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            handlePurchase()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Subscribe Now")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary, in: Capsule())
            .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isPurchasing)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            handleRestore()
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .underline()
        }
        .disabled(isPurchasing)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Actions

    private func handlePurchase() {
        let product: Product? = selectedPlan == .yearly
            ? storeManager.yearlyProduct
            : storeManager.monthlyProduct

        guard let product else { return }

        isPurchasing = true
        HapticManager.medium()

        Task {
            let success = await storeManager.purchase(product)
            if success {
                storeManager.syncSubscriptionStatus(modelContext: modelContext)
                HapticManager.success()
                dismiss()
            } else {
                if storeManager.purchaseError != nil {
                    HapticManager.error()
                }
            }
            isPurchasing = false
        }
    }

    private func handleRestore() {
        isPurchasing = true
        HapticManager.medium()

        Task {
            await storeManager.restorePurchases()
            storeManager.syncSubscriptionStatus(modelContext: modelContext)
            if storeManager.isSubscribed {
                HapticManager.success()
                dismiss()
            } else {
                HapticManager.warning()
            }
            isPurchasing = false
        }
    }
}
