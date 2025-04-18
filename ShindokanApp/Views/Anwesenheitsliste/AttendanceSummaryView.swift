//
//  AttendanceSummaryView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 19.11.24.
//

import SwiftUI
import SwiftData
import Charts

struct AttendanceSummaryView: View {
    @Query var students: [Student]
    var courseType: Course
    
    @State private var monthlyAttendanceCounts: [SumMonthlyAttendance] = []
    
    var body: some View {
        VStack {
            Text("Kurs: \(courseType.rawValue)")
                .font(.title)
                .padding()
            
            Chart(monthlyAttendanceCounts) { item in
                BarMark(x: .value("Monat", item.monthName), y: .value("Anwesenheiten", item.count))}
            .padding()
        }
        .onAppear {
            loadMonthlyAttendanceCounts()
            // Exportiert aktuelle CSV in AppData/Documents..-
            //exportAttendanceCSV()
        }
    }
    
    private func loadMonthlyAttendanceCounts() {
        var attendanceCounts = Array(repeating: 0, count: 12)
        
        let filteredStudents = students.filter { $0.course == courseType }
        
        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let month = Calendar.current.component(.month, from: attendance.date)
                attendanceCounts[month - 1] += 1
            }
        }
        
        monthlyAttendanceCounts = attendanceCounts.enumerated().map { index, count in SumMonthlyAttendance(month: index + 1, count: count)}
    }
    @discardableResult
    private func exportAttendanceCSV() -> URL {
        var csvString = "Name,Anwesenheiten\n"

        let filteredStudents = students.filter { $0.course == courseType }

        for student in filteredStudents {
            let name = "\(student.firstName) \(student.name)"
            let dates = student.attendances
                .filter { $0.isPresent }
                .map { DateFormatter.localizedString(from: $0.date, dateStyle: .short, timeStyle: .none) }
                .joined(separator: ",")
            csvString += "\(name),\(dates)\n"
        }

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Downloads-Verzeichnis nicht gefunden")
            return URL(fileURLWithPath: "")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = documentsURL.appendingPathComponent("Anwesenheiten_\(timestamp).csv", isDirectory: false)
        do {
            try csvString.write(to: filename, atomically: true, encoding: .utf8)
            print("✅ CSV gespeichert unter: \(filename.path)")
        } catch {
            print("❌ Fehler beim Schreiben der CSV: \(error.localizedDescription)")
        }
        return filename
    }
}

struct SumMonthlyAttendance: Identifiable {
    var id: Int { month }
    var month: Int
    var count: Int
    
    var monthName: String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(month: month)) ?? Date()
        return formatter.string(from: date)
    }
}
