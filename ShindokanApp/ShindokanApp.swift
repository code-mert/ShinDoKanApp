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
        .modelContainer(for: [Student.self, Attendance.self, CalendarEntry.self])
    }
}

// Hilfsfunktion: Legt Demodaten an, wenn keine Schüler existieren
func createDemoStudentsIfNeeded(modelContext: ModelContext) {
    let fetchDescriptor = FetchDescriptor<Student>()
    let studentsCount = (try? modelContext.fetch(fetchDescriptor).count) ?? 0
    guard studentsCount == 0 else { return }
    // Beispiel-Demodaten
    let demoStudents = [
        Student(name: "Müller", firstName: "Lena", birthDate: Calendar.current.date(from: DateComponents(year: 2012, month: 3, day: 5))!, belt: .kyu9, weight: "35", lastExamDate: Date(), course: .beginner),
        Student(name: "Schmidt", firstName: "Tom", birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 7, day: 14))!, belt: .kyu7, weight: "42", lastExamDate: Date(), course: .advanced),
        Student(name: "Meier", firstName: "Anna", birthDate: Calendar.current.date(from: DateComponents(year: 2011, month: 11, day: 20))!, belt: .kyu8, weight: "37", lastExamDate: Date(), course: .beginner)
    ]
    for student in demoStudents {
        modelContext.insert(student)
    }
    try? modelContext.save()
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
