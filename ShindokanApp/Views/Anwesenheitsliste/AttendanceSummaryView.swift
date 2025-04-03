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
