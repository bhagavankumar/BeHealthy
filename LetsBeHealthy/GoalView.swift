//
//  GoalView.swift
//  LetsBeHealthy
//
//  Created by Bhagavan Kumar V on 2025-01-27.
//

import SwiftUI

struct GoalView: View {
    @State private var dailyGoal: Int = UserDefaults.standard.integer(forKey: "dailyGoal")
    
    var body: some View {
        VStack {
            TextField("Daily Step Goal", value: $dailyGoal, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Save Goal") {
                UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
