//
//  AppLinks.swift
//  MyFridge
//
//  Central place for the public URLs / contact details shown in the app.
//

import Foundation

enum AppLinks {

    /// Apple's standard EULA. Fine to use as-is; swap for a custom one if you write your own.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // TODO: Replace with a mailbox you actually monitor.
    static let supportEmail = "support@example.com"

    static var supportMailURL: URL {
        URL(string: "mailto:\(supportEmail)?subject=MyFridge%20Support")!
    }
}
