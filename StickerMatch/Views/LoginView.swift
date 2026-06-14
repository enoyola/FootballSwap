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
                Text("StickerMatch")
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
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    auth.signInWithGoogle()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)

                if auth.isLoading {
                    ProgressView().padding(.top, 4)
                }
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
