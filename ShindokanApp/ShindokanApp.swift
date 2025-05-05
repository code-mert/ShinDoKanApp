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
    let modelContainer = try! ModelContainer(for: Student.self, Attendance.self, CalendarEntry.self, ExamDate.self)
    var body: some Scene { // Hauptszene der App
        WindowGroup { // Eine Container-View, die die Hauptansicht der App enthält ("ContentView")
            HomeView()
                .onAppear {
                    migrateExistingStudents(modelContext: modelContainer.mainContext)
                    createDemoStudentsIfNeeded(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}

// Hilfsfunktion: Legt Demodaten an, wenn keine Schüler existieren
func createDemoStudentsIfNeeded(modelContext: ModelContext) {
    let fetchDescriptor = FetchDescriptor<Student>()
    let studentsCount = (try? modelContext.fetch(fetchDescriptor).count) ?? 0
    guard studentsCount == 0 else { return }

    let demoStudents = [
        Student(name: "Müller", firstName: "Lena", birthDate: Calendar.current.date(from: DateComponents(year: 2012, month: 3, day: 5))!, belt: .kyu9, weight: "35", course: .beginner),
        Student(name: "Schmidt", firstName: "Tom", birthDate: Calendar.current.date(from: DateComponents(year: 2010, month: 7, day: 14))!, belt: .kyu7, weight: "42", course: .advanced),
        Student(name: "Meier", firstName: "Anna", birthDate: Calendar.current.date(from: DateComponents(year: 2011, month: 11, day: 20))!, belt: .kyu8, weight: "37", course: .beginner)
    ]

    for student in demoStudents {
        modelContext.insert(student)
        let initialExam = ExamDate(date: Date(), student: student)
        student.examDates.append(initialExam)
        modelContext.insert(initialExam)
    }

    try? modelContext.save()
}

func migrateExistingStudents(modelContext: ModelContext) {
    let fetchDescriptor = FetchDescriptor<Student>()
    if let allStudents = try? modelContext.fetch(fetchDescriptor) {
        for student in allStudents {
            if student.examDates.isEmpty {
                let migratedExam = ExamDate(date: Date(), student: student)
                student.examDates.append(migratedExam)
                modelContext.insert(migratedExam)
            }
        }
        try? modelContext.save()
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
