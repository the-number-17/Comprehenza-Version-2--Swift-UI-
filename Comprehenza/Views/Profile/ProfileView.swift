import SwiftUI

// MARK: - Profile View (fully functional)
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditProfile = false
    @State private var showChangePwd   = false
    @State private var showLogoutAlert = false

    var user: UserAccount? { appState.currentUser }

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich background
                LinearGradient(
                    colors: [Color(hex: "6C5CE7").opacity(0.1), Color(hex: "F8F7FF"), Color(hex: "A29BFE").opacity(0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeroCard
                        statsSection
                        achievementsSection
                        settingsSection
                        logoutButton
                        Text("Comprehenza v1.0  ·  Made with ❤️ for readers")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.bottom, 24)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showChangePwd) {
                ChangePasswordSheet()
                    .environmentObject(appState)
            }
            .alert("Log Out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    HapticManager.notification(.warning)
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again.")
            }
        }
    }

    // MARK: - Hero Card
    var profileHeroCard: some View {
        let av    = user?.avatar ?? .owl
        let level = user?.currentLevel ?? .beginner

        return ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(
                    colors: [av.color.opacity(0.85), av.color.opacity(0.5), Color(hex: "6C5CE7").opacity(0.6)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            // Decorative blobs
            GeometryReader { g in
                Circle().fill(Color.white.opacity(0.1)).frame(width: 120)
                    .offset(x: g.size.width - 60, y: -40)
                Circle().fill(Color.white.opacity(0.07)).frame(width: 70)
                    .offset(x: -20, y: g.size.height - 20)
            }

            VStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 90, height: 90)
                    Text(av.emoji).font(.system(size: 52))
                }
                .shadow(color: .black.opacity(0.15), radius: 10)

                VStack(spacing: 6) {
                    Text(user?.name.isEmpty == false ? user!.name : "Reader")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(user?.email ?? "-")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                    Text("Age \(user?.age ?? 12)")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }

                // Level badge
                HStack(spacing: 6) {
                    Image(systemName: level.icon)
                    Text(level.label + " Reader")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.25)))

                // Edit profile button
                Button {
                    showEditProfile = true
                    HapticManager.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(av.color)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.white))
                }
            }
            .padding(.vertical, 28)
        }
        .padding(.horizontal, 18)
        .shadow(color: av.color.opacity(0.35), radius: 16, y: 8)
    }

    // MARK: - Stats
    var statsSection: some View {
        let scores = user?.categoryScores ?? CategoryScores()
        let statItems: [(String, String, String, Color)] = [
            ("CQ Score",  "\(user?.overallCQ ?? 0)/400", "star.fill",           Color(hex: "FDCB6E")),
            ("Sessions",  "\(user?.sessionHistory.count ?? 0)",   "calendar.badge.clock",  Color(hex: "6C5CE7")),
            ("Day",       "\(user?.journeyDayIndex ?? 0)/30",     "map.fill",              Color(hex: "00B894")),
            ("Best Cat.", bestCategory(scores), "trophy.fill",            Color(hex: "FD79A8"))
        ]

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("📊 Stats")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(statItems, id: \.0) { item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(item.3.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: item.2)
                                .font(.system(size: 18))
                                .foregroundColor(item.3)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.1)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            Text(item.0)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6)
                }
            }
        }
        .padding(.horizontal, 18)
    }

    func bestCategory(_ scores: CategoryScores) -> String {
        let vals: [(ExerciseCategory, Double)] = ExerciseCategory.allCases.map { ($0, scores.score(for: $0)) }
        return vals.max(by: { $0.1 < $1.1 })?.0.shortName ?? "-"
    }

    // MARK: - Achievements
    var achievementsSection: some View {
        let evalDone   = user?.evaluationCompleted ?? false
        let sessions   = user?.sessionHistory.count ?? 0
        let journeyDay = user?.journeyDayIndex ?? 0
        let cq         = user?.overallCQ ?? 0

        let badges: [(String, String, Bool, Color)] = [
            ("First Steps",   "Completed registration",    true,             Color(hex: "6C5CE7")),
            ("Evaluated",     "Completed evaluation test", evalDone,         Color(hex: "FDCB6E")),
            ("On a Roll",     "Completed 5 sessions",      sessions >= 5,    Color(hex: "00B894")),
            ("Week Warrior",  "7-day journey streak",      journeyDay >= 7,  Color(hex: "FD79A8")),
            ("Century Club",  "CQ reached 100",            cq >= 100,        Color(hex: "0984E3")),
            ("Half Way",      "CQ reached 200",            cq >= 200,        Color(hex: "E17055"))
        ]

        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("🏆 Achievements")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(badges, id: \.0) { badge in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(badge.2 ? badge.3.opacity(0.15) : Color(.systemGray5))
                                .frame(width: 50, height: 50)
                            Text(badge.2 ? "🏅" : "🔒")
                                .font(.system(size: 26))
                                .opacity(badge.2 ? 1 : 0.5)
                        }
                        Text(badge.0)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(badge.2 ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(badge.2 ? badge.3.opacity(0.06) : Color(.systemGray6).opacity(0.5))
                    .cornerRadius(14)
                }
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Settings Section
    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("⚙️ Settings")

            VStack(spacing: 0) {
                settingsRow("Edit Profile", icon: "person.circle.fill", color: Color(hex: "6C5CE7")) {
                    showEditProfile = true
                }
                Divider().padding(.leading, 58)
                settingsRow("Change Password", icon: "lock.shield.fill", color: Color(hex: "00B894")) {
                    showChangePwd = true
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 8)
        }
        .padding(.horizontal, 18)
    }

    func settingsRow(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { HapticManager.impact(.light); action() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logout
    var logoutButton: some View {
        Button { showLogoutAlert = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .fontWeight(.semibold)
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundColor(Color(hex: "E17055"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "E17055").opacity(0.1))
            .cornerRadius(16)
        }
        .padding(.horizontal, 18)
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
    }
}

// MARK: - Edit Profile Sheet (fully functional)
struct EditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var name:   String = ""
    @State private var age:    Int    = 12
    @State private var avatar: Avatar = .owl
    @State private var saved   = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "6C5CE7").opacity(0.08), Color(hex: "F8F7FF")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if saved {
                            savedConfirmation
                        } else {
                            // Current avatar preview
                            ZStack {
                                Circle().fill(avatar.color.opacity(0.2)).frame(width: 90, height: 90)
                                Text(avatar.emoji).font(.system(size: 52))
                            }
                            .padding(.top, 20)

                            // Avatar Grid
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Choose Avatar")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 20)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                                    ForEach(Avatar.allCases, id: \.self) { av in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) { avatar = av }
                                            HapticManager.impact(.light)
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(avatar == av ? av.color.opacity(0.2) : Color(.systemGray6))
                                                        .frame(width: 56, height: 56)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(avatar == av ? av.color : Color.clear, lineWidth: 2.5)
                                                        )
                                                    Text(av.emoji).font(.system(size: 30))
                                                }
                                                Text(av.rawValue.capitalized)
                                                    .font(.system(size: 10, design: .rounded))
                                                    .foregroundColor(avatar == av ? av.color : .secondary)
                                            }
                                            .scaleEffect(avatar == av ? 1.08 : 1)
                                            .animation(.spring(response: 0.25), value: avatar)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Name & Age
                            VStack(spacing: 14) {
                                AuthTextField(icon: "person.fill", placeholder: "Name", text: $name)

                                // Age stepper
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(Color(hex: "6C5CE7").opacity(0.12)).frame(width: 42, height: 42)
                                        Image(systemName: "birthday.cake.fill")
                                            .foregroundColor(Color(hex: "6C5CE7")).font(.system(size: 18))
                                    }
                                    Text("Age")
                                        .font(.system(size: 16, design: .rounded))
                                    Spacer()
                                    HStack(spacing: 0) {
                                        Button { if age > 9 { age -= 1 } } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(age > 9 ? Color(hex: "6C5CE7") : .secondary.opacity(0.3))
                                        }
                                        Text("\(age)")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                            .frame(width: 44)
                                        Button { if age < 16 { age += 1 } } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(age < 16 ? Color(hex: "6C5CE7") : .secondary.opacity(0.3))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 6))
                            }
                            .padding(.horizontal, 20)

                            // Save button
                            Button {
                                appState.updateProfile(name: name, age: age, avatar: avatar)
                                HapticManager.notification(.success)
                                withAnimation { saved = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                            } label: {
                                Text("Save Changes")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "6C5CE7"))
                }
            }
        }
        .onAppear {
            name   = appState.currentUser?.name   ?? ""
            age    = appState.currentUser?.age    ?? 12
            avatar = appState.currentUser?.avatar ?? .owl
        }
    }

    var savedConfirmation: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("✅").font(.system(size: 70))
            Text("Profile Updated!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "00B894"))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Change Password Sheet (fully functional)
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentPwd = ""
    @State private var newPwd     = ""
    @State private var confirmPwd = ""
    @State private var errorMsg   = ""
    @State private var success    = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "00B894").opacity(0.08), Color(hex: "F8F7FF")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    if success {
                        VStack(spacing: 16) {
                            Text("🔐✅").font(.system(size: 60))
                            Text("Password Updated!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "00B894"))
                            Button("Done") { dismiss() }
                                .buttonStyle(PrimaryButtonStyle(color: Color(hex: "00B894")))
                                .padding(.horizontal, 40)
                        }
                    } else {
                        VStack(spacing: 20) {
                            VStack(spacing: 6) {
                                Text("🔒").font(.system(size: 60))
                                Text("Change Password")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                Text("Enter your current and new passwords")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 14) {
                                AuthTextField(icon: "lock.fill",     placeholder: "Current password",     text: $currentPwd, isSecure: true)
                                AuthTextField(icon: "lock.rotation", placeholder: "New password (min 6)", text: $newPwd, isSecure: true)
                                AuthTextField(icon: "checkmark.shield", placeholder: "Confirm new password", text: $confirmPwd, isSecure: true)

                                if !errorMsg.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text(errorMsg)
                                    }
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color(hex: "E17055"))
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: "E17055").opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 24)

                            Button("Update Password") {
                                errorMsg = ""
                                guard newPwd == confirmPwd else {
                                    errorMsg = "Passwords don't match."
                                    HapticManager.notification(.error)
                                    return
                                }
                                if let err = appState.changePassword(current: currentPwd, new: newPwd) {
                                    errorMsg = err
                                    HapticManager.notification(.error)
                                } else {
                                    withAnimation { success = true }
                                    HapticManager.notification(.success)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(color: Color(hex: "00B894")))
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "6C5CE7"))
                }
            }
        }
    }
}
