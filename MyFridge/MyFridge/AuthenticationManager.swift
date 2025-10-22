//
//  AuthenticationManager.swift
//  MyFridge
//
//  Manages Sign in with Apple authentication
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var authError: String?
    
    // MARK: - UserDefaults Keys
    private let userIDKey = "user_id"
    private let userNameKey = "user_name"
    private let userEmailKey = "user_email"
    
    init() {
        // Check if user is already logged in
        checkAuthenticationState()
    }
    
    // MARK: - Check Existing Auth
    func checkAuthenticationState() {
        if let savedUserID = UserDefaults.standard.string(forKey: userIDKey) {
            self.userID = savedUserID
            self.userName = UserDefaults.standard.string(forKey: userNameKey)
            self.userEmail = UserDefaults.standard.string(forKey: userEmailKey)
            self.isAuthenticated = true
            
            // Verify credential status
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: savedUserID) { state, error in
                Task { @MainActor in
                    switch state {
                    case .authorized:
                        self.isAuthenticated = true
                    case .revoked, .notFound:
                        self.signOut()
                    default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Sign In Result
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extract user info
                let userID = appleIDCredential.user
                
                // Name and email are only provided on FIRST sign-in
                let firstName = appleIDCredential.fullName?.givenName ?? ""
                let lastName = appleIDCredential.fullName?.familyName ?? ""
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                let email = appleIDCredential.email
                
                // Save to UserDefaults
                UserDefaults.standard.set(userID, forKey: userIDKey)
                if !fullName.isEmpty {
                    UserDefaults.standard.set(fullName, forKey: userNameKey)
                }
                if let email = email {
                    UserDefaults.standard.set(email, forKey: userEmailKey)
                }
                
                // Update state
                self.userID = userID
                self.userName = fullName.isEmpty ? nil : fullName
                self.userEmail = email
                self.isAuthenticated = true
                self.authError = nil
                
                print("✅ Sign in successful - UserID: \(userID)")
                
                // TODO: Send userID to your backend to create/link account
                // syncUserToBackend(userID: userID, name: fullName, email: email)
            }
            
        case .failure(let error):
            self.authError = error.localizedDescription
            print("❌ Sign in failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        
        self.userID = nil
        self.userName = nil
        self.userEmail = nil
        self.isAuthenticated = false
        
        print("👋 User signed out")
    }
    
    // MARK: - Backend Sync (Placeholder)
    // You'll implement this when you choose Firebase/Supabase/CloudKit
    private func syncUserToBackend(userID: String, name: String, email: String?) {
        // Example pseudo-code:
        // let userData = ["id": userID, "name": name, "email": email ?? ""]
        // FirebaseService.createOrUpdateUser(userData)
        // OR
        // SupabaseService.upsertUser(userData)
    }
}
