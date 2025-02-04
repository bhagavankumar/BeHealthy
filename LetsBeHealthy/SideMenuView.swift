import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedMenu: String?
    @StateObject private var authManager = AuthManager.shared
    @Binding var selectedTab: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                // Menu Buttons with slight gap from the left edge
                Button(action: {
                                    selectedTab = "Steps"  // Switch to Steps tab
                                    isMenuOpen = false
                                }) {
                                    Label("Steps", systemImage: "figure.walk")
                                        .font(.headline)
                                        .padding(.vertical, 12)
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                Button(action: {
                    selectedTab = "Rewards"  // Switch to Rewards tab
                    isMenuOpen = false
                }) {
                    Label("Rewards", systemImage: "gift.fill")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                Button(action: {
                                    selectedTab = "Analytics"  // Switch to Analytics tab
                                    isMenuOpen = false
                                }) {
                                    Label("Analytics", systemImage: "chart.bar.fill")
                                        .font(.headline)
                                        .padding(.vertical, 12)
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }

                Button(action: {
                    selectedTab = "Profile"
                    isMenuOpen = false
                }) {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Button(action: {
                    selectedMenu = "Settings"
                    isMenuOpen = false
                }) {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Spacer()

                // Logout Button (with same gap)
                Button(action: {
                    authManager.signOut()
                }) {
                    Label("Logout", systemImage: "arrow.backward.square.fill")
                        .font(.headline)
                        .padding(.vertical, 15)
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .padding(.bottom, 30)
            }
            .padding(.top, 50)
            .frame(width: 250, height: UIScreen.main.bounds.height * 0.9)
            .background(Color(.systemGray6))
            .edgesIgnoringSafeArea(.top)

            Spacer()
        }
        .background(
            Color.black.opacity(isMenuOpen ? 0.4 : 0)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isMenuOpen = false
                    }
                }
        )
        .offset(x: isMenuOpen ? 0 : -300)
        .animation(.easeInOut(duration: 0.25), value: isMenuOpen)
    }
}
