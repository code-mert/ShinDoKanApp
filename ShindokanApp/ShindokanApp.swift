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
    let modelContainer = try! ModelContainer(for: Student.self, Attendance.self, ExamDate.self, WorkoutPlan.self, DrillPreference.self)
    var body: some Scene { // Hauptszene der App
        WindowGroup { // Eine Container-View, die die Hauptansicht der App enthält ("ContentView")
            MainTabView()
                .onAppear {
                    createDemoStudentsIfNeeded(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}

// Hilfsfunktion: Legt Demodaten an, wenn keine Schüler existieren
// Hilfsfunktion: Legt Demodaten an, wenn keine Schüler existieren
func createDemoStudentsIfNeeded(modelContext: ModelContext) {
    #if targetEnvironment(simulator)
    var fetchDescriptor = FetchDescriptor<Student>()
    fetchDescriptor.fetchLimit = 1
    
    // Check if any student exists efficiently
    if let count = try? modelContext.fetchCount(fetchDescriptor), count > 0 {
        return
    }

    let demoStudents = [
        Student(name: "Müller", firstName: "Lena", birthDate: Calendar.current.date(from: DateComponents(year: 2012, month: 3, day: 5))!, belt: .kyu9, weight: "35", course: .beginner),
        Student(name: "Schmidt", firstName: "Tom", birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 7, day: 14))!, belt: .kyu7, weight: "42", course: .advanced),
        Student(name: "Meier", firstName: "Anna", birthDate: Calendar.current.date(from: DateComponents(year: 2011, month: 11, day: 20))!, belt: .kyu8, weight: "37", course: .beginner),
        // Neue Schüler
        Student(name: "Becker", firstName: "Lars", birthDate: Calendar.current.date(from: DateComponents(year: 2013, month: 1, day: 10))!, belt: .kyu9, weight: "32", course: .beginner),
        Student(name: "Wagner", firstName: "Sophie", birthDate: Calendar.current.date(from: DateComponents(year: 2009, month: 5, day: 22))!, belt: .kyu7, weight: "40", course: .advanced),
        Student(name: "Weber", firstName: "Jonas", birthDate: Calendar.current.date(from: DateComponents(year: 2012, month: 8, day: 30))!, belt: .kyu9, weight: "34", course: .beginner),
        Student(name: "Schulz", firstName: "Mia", birthDate: Calendar.current.date(from: DateComponents(year: 2008, month: 12, day: 5))!, belt: .kyu6, weight: "45", course: .advanced),
        Student(name: "Hoffmann", firstName: "Ben", birthDate: Calendar.current.date(from: DateComponents(year: 2011, month: 4, day: 18))!, belt: .kyu89, weight: "36", course: .beginner),
        Student(name: "Koch", firstName: "Emma", birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 9, day: 12))!, belt: .kyu5, weight: "48", course: .advanced),
        Student(name: "Richter", firstName: "Noah", birthDate: Calendar.current.date(from: DateComponents(year: 2013, month: 2, day: 28))!, belt: .kyu8, weight: "38", course: .beginner),
        Student(name: "Klein", firstName: "Lea", birthDate: Calendar.current.date(from: DateComponents(year: 2007, month: 6, day: 15))!, belt: .kyu4, weight: "50", course: .advanced)
    ]

    for student in demoStudents {
        modelContext.insert(student)
        
        // Füge ein initiales Prüfungsdatum hinzu (nur für neue Schüler)
        let initialExam = ExamDate(date: Date(), student: student)
        student.examDates.append(initialExam)
        modelContext.insert(initialExam)
    }

    try? modelContext.save()
    #endif
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

