//
//  AttendanceSingleChartView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 23.12.24.
//

import SwiftUI
import Charts

struct AttendanceSingleChartView: View {
    var student: Student
    
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Text("\(student.firstName) \(student.name)")
                .font(.title2)
                .padding()

            Chart {
                ForEach(monthlyAttendanceData(), id: \.month) { data in
                    BarMark(
                        x: .value("Monat", data.month),
                        y: .value("Anwesenheit", data.attendanceCount)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
        }
    }
    
    // Funktion, um die Anwesenheit pro Monat zu berechnen
    private func monthlyAttendanceData() -> [MonthlyAttendance] {
        let calendar = Calendar.current
        var attendanceCounts: [Int: Int] = [:] // Monat -> Anzahl der Anwesenheiten

        for attendance in student.attendances {
            if attendance.isPresent {
                let month = calendar.component(.month, from: attendance.date)
                attendanceCounts[month, default: 0] += 1
            }
        }

        // Daten in ein Array aus `MonthlyAttendance` konvertieren
        return (1...12).map { month in
            MonthlyAttendance(
                month: monthName(for: month),
                attendanceCount: attendanceCounts[month, default: 0])
        }
    }

    // Hilfsfunktion: Monatsname für einen Monat
    private func monthName(for month: Int) -> String {
        let shortMonthNames = ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
        return shortMonthNames[month - 1] // month - 1, weil Array nullbasiert
    }
}

// Datenmodell für die Diagrammanzeige
struct MonthlyAttendance {
    let month: String
    let attendanceCount: Int
}
