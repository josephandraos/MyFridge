//
//  SettingsView.swift
//  MyFridge
//
//  Settings for notification preferences
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @State private var showingResetAlert = false
    @State private var showingSaveConfirmation = false
    @State private var showingSignOutAlert = false
    @State private var selectedDigestHour = 9
    @State private var selectedDigestMinute = 0
    
    var body: some View {
        NavigationStack {
            Form {
                // App Info Section
                appInfoSection
                
                // Notification Status Section
                notificationStatusSection
                
                // Notification Settings (only if enabled)
                if notificationManager.notificationPermissionGranted {
                    reminderTimeSection
                    notificationStyleSection
                    digestTimeSection
                    testNotificationSection
                    advancedSection
                }
                
                // About Section
                aboutSection
                
                // Account Section
                accountSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    notificationManager.resetNotificationSettings()
                    showingSaveConfirmation = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all notification settings to defaults and clear pending notifications. This cannot be undone.")
            }
            .alert("Settings Saved", isPresented: $showingSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your notification preferences have been updated successfully.")
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authenticationManager.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out? You'll need to sign in again to access your fridge.")
            }
            .onAppear {
                loadDigestTime()
            }
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Image(systemName: "refrigerator.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MyFridge")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("Track groceries, reduce waste")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(.leading, 8)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Notification Status Section
    
    private var notificationStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(notificationManager.notificationPermissionGranted ?
                              Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: notificationManager.notificationPermissionGranted ?
                          "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(notificationManager.notificationPermissionGranted ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(notificationStatusText)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(notificationManager.notificationPermissionGranted ? LocalizedStringKey("Enabled") : LocalizedStringKey("Disabled"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(notificationManager.notificationPermissionGranted ? .green : .red)
            }
            .padding(.vertical, 4)
            
            if !notificationManager.notificationPermissionGranted {
                Button(action: openAppSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                    }
                }
                .foregroundStyle(.blue)
            }
        } header: {
            Text("Notification Status")
        } footer: {
            Text("MyFridge needs notification permission to remind you before items expire. Enable notifications in iOS Settings to reduce food waste.")
        }
    }
    
    // MARK: - Reminder Time Section
    
    private var reminderTimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Notify")
                        .font(.system(size: 17))
                    
                    Spacer()
                    
                    Text("\(notificationManager.defaultLeadTimeDays) days")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                
                Stepper("", value: $notificationManager.defaultLeadTimeDays, in: 1...7)
                    .labelsHidden()
                
                // Visual indicator
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        Rectangle()
                            .fill(day <= notificationManager.defaultLeadTimeDays ?
                                  Color.blue : Color.gray.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .clipShape(Capsule())
            }
            .padding(.vertical, 4)
            
            // Quick presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                
                HStack(spacing: 8) {
                    PresetButton(title: "1 day", value: 1, current: $notificationManager.defaultLeadTimeDays)
                    PresetButton(title: "3 days", value: 3, current: $notificationManager.defaultLeadTimeDays)
                    PresetButton(title: "5 days", value: 5, current: $notificationManager.defaultLeadTimeDays)
                    PresetButton(title: "1 week", value: 7, current: $notificationManager.defaultLeadTimeDays)
                }
            }
        } header: {
            Text("Default Reminder Time")
        } footer: {
            Text("Get notified this many days before items expire. This can be customized for individual items.")
        }
        .onChange(of: notificationManager.defaultLeadTimeDays) { oldValue, newValue in
            notificationManager.saveSettings()
        }
    }
    
    // MARK: - Notification Style Section
    
    private var notificationStyleSection: some View {
        Section {
            Toggle(isOn: $notificationManager.useDailyDigest) {
                HStack(spacing: 12) {
                    Image(systemName: notificationManager.useDailyDigest ?
                          "calendar.badge.clock" : "bell.badge")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Digest")
                            .font(.system(size: 17, weight: .medium))
                        
                        Text(notificationManager.useDailyDigest ?
                             LocalizedStringKey("One summary per day") : LocalizedStringKey("Individual notifications"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.blue)
        } header: {
            Text("Notification Style")
        } footer: {
            if notificationManager.useDailyDigest {
                Text("Receive one daily summary at your chosen time instead of individual notifications for each item. This reduces notification clutter.")
            } else {
                Text("Receive individual notifications for each expiring item at the scheduled time.")
            }
        }
        .onChange(of: notificationManager.useDailyDigest) { oldValue, newValue in
            notificationManager.saveSettings()
        }
    }
    
    // MARK: - Digest Time Section
    
    private var digestTimeSection: some View {
        Group {
            if notificationManager.useDailyDigest {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        
                        Text("Digest Time")
                            .font(.system(size: 17))
                        
                        Spacer()
                        
                        Picker("Hour", selection: $selectedDigestHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        
                        Text(":")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Picker("Minute", selection: $selectedDigestMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                    }
                    
                    // Quick time presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Times")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                        
                        HStack(spacing: 8) {
                            TimePresetButton(title: "Morning", hour: 9, minute: 0,
                                           selectedHour: $selectedDigestHour,
                                           selectedMinute: $selectedDigestMinute)
                            TimePresetButton(title: "Noon", hour: 12, minute: 0,
                                           selectedHour: $selectedDigestHour,
                                           selectedMinute: $selectedDigestMinute)
                            TimePresetButton(title: "Evening", hour: 18, minute: 0,
                                           selectedHour: $selectedDigestHour,
                                           selectedMinute: $selectedDigestMinute)
                        }
                    }
                } header: {
                    Text("Daily Digest Time")
                } footer: {
                    Text("Your daily summary will arrive at \(String(format: "%02d:%02d", selectedDigestHour, selectedDigestMinute))")
                }
                .onChange(of: selectedDigestHour) { oldValue, newValue in
                    updateDigestTime()
                }
                .onChange(of: selectedDigestMinute) { oldValue, newValue in
                    updateDigestTime()
                }
            }
        }
    }
    
    // MARK: - Test Notification Section
    
    private var testNotificationSection: some View {
        Section {
            Button(action: sendTestNotification) {
                HStack {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    
                    Text("Send Test Notification")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
            }
        } header: {
            Text("Test Notifications")
        } footer: {
            Text("Send a test notification to verify your settings are working correctly. The notification will appear in 5 seconds.")
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        Section {
            Button(role: .destructive, action: { showingResetAlert = true }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20))
                        .frame(width: 28)
                    
                    Text("Reset All Settings")
                        .font(.system(size: 17))
                }
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("Reset all notification preferences to their default values. This will also clear all pending notifications.")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            Link(destination: AppLinks.termsOfUse) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    
                    Text("Terms of Service")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Link(destination: AppLinks.supportMailURL) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                        .frame(width: 28)

                    Text("Contact Support")
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(AppLinks.supportEmail)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section {
            Button(role: .destructive, action: { showingSignOutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .frame(width: 28)
                    
                    Text("Sign Out")
                        .font(.system(size: 17))
                }
            }
        } header: {
            Text("Account")
        } footer: {
            if let userName = authenticationManager.userName {
                Text("Signed in as \(userName)")
            } else if let userEmail = authenticationManager.userEmail {
                Text("Signed in as \(userEmail)")
            } else {
                Text("Sign out of your MyFridge account")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var notificationStatusText: LocalizedStringKey {
        switch notificationManager.notificationStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied - Enable in Settings"
        case .notDetermined:
            return "Not configured"
        case .provisional:
            return "Provisional access"
        case .ephemeral:
            return "Temporary access"
        @unknown default:
            return "Unknown status"
        }
    }
    
    // MARK: - Helper Functions
    
    private func openAppSettings() {
        notificationManager.openNotificationSettings()
    }
    
    private func loadDigestTime() {
        selectedDigestHour = notificationManager.digestTime.hour ?? 9
        selectedDigestMinute = notificationManager.digestTime.minute ?? 0
    }
    
    private func updateDigestTime() {
        notificationManager.digestTime = DateComponents(hour: selectedDigestHour, minute: selectedDigestMinute)
        notificationManager.saveSettings()
    }
    
    private func sendTestNotification() {
        Task {
            await notificationManager.sendTestNotification()
        }
    }
}

// MARK: - Preset Button Component

struct PresetButton: View {
    let title: LocalizedStringKey
    let value: Int
    @Binding var current: Int
    
    var body: some View {
        Button(action: { current = value }) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(current == value ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(current == value ? Color.blue : Color.blue.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time Preset Button Component

struct TimePresetButton: View {
    let title: LocalizedStringKey
    let hour: Int
    let minute: Int
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    private var isSelected: Bool {
        selectedHour == hour && selectedMinute == minute
    }
    
    var body: some View {
        Button(action: {
            selectedHour = hour
            selectedMinute = minute
        }) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager.shared)
}
