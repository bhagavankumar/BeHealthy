//
//  NotificationsSettingsView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-02-03.
//


import SwiftUI

struct NotificationsSettingsView: View {
    @State private var receiveGeneralNotifications = true
    @State private var receivePromotions = false
    @State private var receiveStepReminders = true

    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("General Notifications", isOn: $receiveGeneralNotifications)
                Toggle("Promotions & Offers", isOn: $receivePromotions)
                Toggle("Step Reminders", isOn: $receiveStepReminders)
            }
        }
        .navigationTitle("Notification Settings")
    }
}

struct NotificationsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsSettingsView()
    }
}