//
//  AppLinks.swift
//  MyFridge
//
//  Central place for the public URLs / contact details shown in the app.
//

import Foundation

enum AppLinks {

    // TODO: Replace with your real privacy policy URL before submitting to the App Store.
    // App Store Connect requires a working privacy policy link for apps with subscriptions.
    static let privacyPolicy = URL(string: "https://example.com/myfridge/privacy")!

    /// Apple's standard EULA. Fine to use as-is; swap for a custom one if you write your own.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // TODO: Replace with a mailbox you actually monitor.
    static let supportEmail = "support@example.com"

    static var supportMailURL: URL {
        URL(string: "mailto:\(supportEmail)?subject=MyFridge%20Support")!
    }
}
