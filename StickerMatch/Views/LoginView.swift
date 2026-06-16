import SwiftUI
import AuthenticationServices

/// Login screen: app name, subtitle, Apple + Google sign-in, safety note.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                Text("FootballSwap")
                    .font(.largeTitle.bold())
                Text("Complete your album faster. Find people nearby who have the stickers you need.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    auth.configureAppleRequest(request)
                } onCompletion: { result in
                    auth.handleAppleCompletion(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    auth.signInWithGoogle()
                } label: {
                    HStack(spacing: 12) {
                        Image("GoogleG")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                if auth.isLoading {
                    ProgressView().padding(.top, 4)
                }

                Text("By continuing, you agree to our [Terms of Use](https://enoyola.github.io/FootballSwap/terms.html) and [Privacy Policy](https://enoyola.github.io/FootballSwap/privacy.html).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .tint(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .padding(.horizontal)

            if let error = auth.errorMessage {
                ErrorBanner(message: error) { auth.errorMessage = nil }
            }

            Spacer()

            SafetyDisclaimerView()
                .padding(.horizontal)
                .padding(.bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pitchBackground()
    }
}
