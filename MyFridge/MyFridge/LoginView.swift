//
//  LoginView.swift
//  MyFridge
//
//  Login screen (Sign in with Apple)
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // MyFridge title
                Text("MyFridge")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.bottom, 8)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : -20)
                
                // Fridge icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.blue.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 80,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                    
                    Image(systemName: "refrigerator.fill")
                        .font(.system(size: 150))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: -5, y: 10)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 15)
                }
                .scaleEffect(isAnimating ? 1 : 0.8)
                .padding(.bottom, 16)
                
                // Subtitle
                Text("Track groceries, reduce waste")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .opacity(isAnimating ? 1 : 0)
                
                Spacer()
                    .frame(height: 60)
                
                // Features list
                VStack(spacing: 20) {
                    FeatureBullet(icon: "camera.fill", text: "Scan grocery receipts")
                    FeatureBullet(icon: "calendar.badge.clock", text: "Track expiration dates")
                    FeatureBullet(icon: "bell.fill", text: "Get smart reminders")
                    FeatureBullet(icon: "leaf.fill", text: "Reduce food waste")
                }
                .padding(.horizontal, 40)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                
                // Sign in button section
                VStack(spacing: 16) {
                    // Custom Sign in with Apple button with better visibility
                    CustomSignInWithAppleButton()
                        .frame(height: 50)
                        .padding(.horizontal, 40)
                    
                    Text("Secure sign-in with your Apple ID")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
        .alert("Sign In Error", isPresented: .constant(authManager.authError != nil)) {
            Button("OK") {
                authManager.authError = nil
            }
        } message: {
            if let error = authManager.authError {
                Text(error)
            }
        }
    }
}

// MARK: - Custom Sign in with Apple Button (Better Dark Mode Support)

struct CustomSignInWithAppleButton: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        SignInWithAppleButtonRepresentable(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                authManager.handleSignInWithApple(result: result)
            }
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .cornerRadius(8)
    }
}

// MARK: - Feature Bullet

struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - UIKit Bridge for Sign in with Apple Button
struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton()
        button.addTarget(context.coordinator, action: #selector(Coordinator.handlePress), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void, onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handlePress() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else {
                return UIWindow()
            }
            return window
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
