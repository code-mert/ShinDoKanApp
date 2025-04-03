//
//  ShindokanAppApp.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

@main // markiert Einstiegspunkt der App
struct ShindokanApp: App { // Hauptstruktur der App
    var body: some Scene { // Hauptszene der App
        WindowGroup { // Eine Container-View, die die Hauptansicht der App enthält ("ContentView")
            HomeView()
        }
        .modelContainer(for: [Student.self, Attendance.self])
    }
}

// Erweiterung für Date zur Berechnung des Alters
extension Date {
    func age() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year!
    }
}



