import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutConfirm = false
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header — matching HomeView style
                    HStack {
                        Text("Profile")
                            .font(LaymanFont.logo(28))
                            .foregroundColor(.laymanDark)
                        
                        Spacer()
                    }
                    .padding(.horizontal, LaymanDimension.screenPadding)
                    .padding(.top, 8)
                    
                    // Profile avatar and info
                    VStack(spacing: 24) {
                        // Profile avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.laymanPeach, .laymanOrange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            Text(initials)
                                .font(LaymanFont.title(32))
                                .foregroundColor(.white)
                        }
                        
                        // User info
                        VStack(spacing: 6) {
                            Text(authViewModel.profile?.full_name ?? authViewModel.currentUserEmail ?? "User")
                                .font(LaymanFont.headline(18))
                                .foregroundColor(.laymanDark)
                            
                            Text("Reader")
                                .font(LaymanFont.caption(13))
                                .foregroundColor(.laymanGray)
                        }
                        
                        // Info cards
                        VStack(spacing: 12) {
                            profileRow(icon: "person.fill", title: "Full Name", value: authViewModel.profile?.full_name ?? "—")
                            profileRow(icon: "envelope.fill", title: "Email", value: authViewModel.currentUserEmail ?? "—")
                            profileRow(icon: "calendar", title: "Age", value: authViewModel.profile?.age ?? "—")
                            profileRow(icon: "phone.fill", title: "Phone", value: authViewModel.profile?.phone ?? "—")
                            
                            Divider().padding(.vertical, 8)
                            
                            profileRow(icon: "info.circle.fill", title: "App Version", value: "1.0.0")
                            profileRow(icon: "doc.text.fill", title: "Terms of Service", value: "")
                            profileRow(icon: "shield.fill", title: "Privacy Policy", value: "")
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // Sign out button
                        Button {
                            showSignOutConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(LaymanFont.headline(16))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(LaymanDimension.smallCornerRadius)
                        }
                        
                        // Built with tag
                        VStack(spacing: 4) {
                            Text("Built with ❤️ using Antigravity")
                                .font(LaymanFont.small(11))
                                .foregroundColor(.laymanLightGray)
                            
                            Text("Layman — News made simple")
                                .font(LaymanFont.small(11))
                                .foregroundColor(.laymanLightGray)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, LaymanDimension.screenPadding)
                    
                    // Bottom padding for tab bar
                    Color.clear.frame(height: 80)
                }
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var initials: String {
        if let name = authViewModel.profile?.full_name, !name.isEmpty {
            let parts = name.split(separator: " ")
            if let first = parts.first?.prefix(1), let last = parts.last?.prefix(1), parts.count > 1 {
                return (String(first) + String(last)).uppercased()
            }
            return String(name.prefix(1)).uppercased()
        }
        guard let email = authViewModel.currentUserEmail else { return "?" }
        return String(email.prefix(1)).uppercased()
    }
    
    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.laymanOrange)
                .frame(width: 36, height: 36)
                .background(Color.laymanOrange.opacity(0.1))
                .cornerRadius(10)
            
            Text(title)
                .font(LaymanFont.body(15))
                .foregroundColor(.laymanDark)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(LaymanFont.caption(13))
                    .foregroundColor(.laymanGray)
                    .lineLimit(1)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.laymanLightGray)
            }
        }
        .padding(14)
        .background(Color.laymanCardBg)
        .cornerRadius(LaymanDimension.smallCornerRadius)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
