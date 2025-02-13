import SwiftUI
import AVFoundation
import HealthKit

struct StepTrackerView: View {
    @State private var steps: Int = 0
    @State private var isMenuOpen: Bool = false
    @State private var selectedMenu: String? = nil
    @Binding var selectedTab: String  // This binds to the bottom tab navigation
    @State private var showSettings: Bool = false
    @State private var viewLoaded = false
    @State private var isMeditationPresented = false
    @State private var showMeditationAlert: Bool = false
    @AppStorage("stepGoal") private var stepGoal: Int = 10000
    @AppStorage("stepCoinsFromSteps") private var stepCoinsFromSteps: Int = 0 // StepCoins from walking
    @AppStorage("stepCoinsFromMeditation") private var stepCoinsFromMeditation: Int = 0 // StepCoins from meditation
    @AppStorage("lastMeditationDate") private var lastMeditationDate: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Always display the Step Tracker as the default view
                stepTrackerContent
                    .disabled(isMenuOpen)
                    .blur(radius: isMenuOpen ? 5 : 0)
                    .opacity(viewLoaded ? 1 : 0)  // Forces re-render
                    .onAppear {
                        withAnimation {
                            viewLoaded = true
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                
                // Side Menu
                if isMenuOpen {
                    SideMenuView(isMenuOpen: $isMenuOpen, selectedMenu: $selectedMenu, selectedTab: $selectedTab)
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
            }
                
                .sheet(isPresented: $showSettings, onDismiss: {
                    selectedMenu = nil  // Reset the menu selection after closing
                }) {
                    SettingsView()
                }
                .onAppear(perform: fetchSteps)
                .onChange(of: selectedMenu) {
                    if selectedMenu == "Settings" {
                        showSettings = true
                        isMenuOpen = false
                    } else if selectedMenu == "Rewards" {
                        selectedTab = "Rewards"
                        isMenuOpen = false
                    } else if selectedMenu == "Profile" {
                        selectedTab = "Profile"
                        isMenuOpen = false
                    }
                }
                
            }
        
    }

    private var stepTrackerContent: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    isMenuOpen.toggle()
                                }
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .resizable()
                                    .frame(width: 30, height: 20)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            Spacer()
                        }
                        
                        Text("Step Tracker")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        VStack {
                            Text("Today's Steps")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(steps)")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        
                        Spacer()
                        ProgressRingView(progress: Double(steps) / Double(stepGoal), color: .blue)
                            .frame(width: 200, height: 200)
                        
                        Button(action: fetchSteps) {
                            Text("Refresh Steps")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 30)
                        
                        Button(action: shareAchievement) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .shadow(radius: 5)
                        Button(action: {
                            lastMeditationDate = "" // Reset the meditation tracking for testing
                            UserDefaults.standard.set("", forKey: "lastMeditationDate") // Ensure it saves
                            print("✅ Last meditation date reset for testing.")
                        }) {
                            Text("Reset Meditation Session")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Relax & Earn Step Coins")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))

                            if lastMeditationDate == DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none) {
                                Text("You have already meditated today! Come back tomorrow.")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                                    .padding(.top, 5)
                            } else {
                                Text("Earn rewards by meditating daily")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))

                                Divider().background(Color.white.opacity(0.3)) // Separator

                                HStack {
                                    Image(systemName: "leaf.circle.fill") // Meditation Icon
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.green)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Start Meditation")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("Earn 100 - 300 Step Coins")
                                            .font(.subheadline)
                                            .foregroundColor(.yellow)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        if lastMeditationDate == DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none) {
                                            showMeditationAlert = true // Show alert if session is already completed today
                                        } else {
                                            isMeditationPresented = true
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(lastMeditationDate == DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none) ? .gray : .white.opacity(0.8)) // Change color when disabled
                                            .padding()
                                            .background(Circle().fill(Color.blue.opacity(0.8)))
                                    }
                                    .alert(isPresented: $showMeditationAlert) {
                                        Alert(
                                            title: Text("Meditation Limit Reached"),
                                            message: Text("StepCoins can be earned through meditation only once in a day. Try again tomorrow!"),
                                            dismissButton: .default(Text("OK"))
                                        )
                                    }
                                    .disabled(lastMeditationDate == DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))
                                }
                                .fullScreenCover(isPresented: $isMeditationPresented) {
                                    MeditationView()
                                }
                                .padding(.top, 5)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.2)))
                        .shadow(radius: 5)
                        .padding()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func shareAchievement() {
        let activityVC = UIActivityViewController(
            activityItems: ["I just walked \(steps) steps today! 🚶♂️ #StepRewards"],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive && $0 is UIWindowScene
        }) as? UIWindowScene {
            windowScene.windows.first(where: \.isKeyWindow)?.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    func fetchSteps() {
        let healthStore = HKHealthStore()
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Step Count is not available.")
            return
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(String(describing: error))")
                return
            }
            DispatchQueue.main.async {
                self.steps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }
}
// Progress Ring View Component
struct ProgressRingView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270))
            
            Text("\(Int(progress * 100))%")
                .font(.title)
                .bold()
                .foregroundColor(.white)
        }
    }
}
