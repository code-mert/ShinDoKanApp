import SwiftUI
import SwiftData
import Charts

struct AttendanceSummaryView: View {
    @Query var students: [Student]
    var courseType: Course
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var monthlyAttendanceCounts: [SumMonthlyAttendance] = []
    @State private var selectedMonth: SumMonthlyAttendance? = nil
    
    var body: some View {
        VStack {
            Text("Kurs: \(courseType.rawValue)")
                .font(.title)
                .padding()
            
            if !availableYears.isEmpty {
                Menu {
                    ForEach(availableYears, id: \.self) { year in
                        Button(String(year)) {
                            selectedYear = year
                            loadMonthlyAttendanceCounts()
                        }
                    }
                } label: {
                    HStack {
                        Text("\(String(selectedYear))")
                        Image(systemName: "chevron.down")
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if let selected = selectedMonth {
                HStack {
                    Text("📊 \(selected.count) im \(selected.monthName)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Chart {
                ForEach(monthlyAttendanceCounts) { item in
                    BarMark(
                        x: .value("Monat", item.monthName),
                        y: .value("Anwesenheiten", item.count)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let origin = geometry[plotFrame].origin
                                    let location = CGPoint(x: value.location.x - origin.x, y: value.location.y - origin.y)
                                    if let (monthName, _) = proxy.value(at: location, as: (String, Int).self) {
                                        if let selected = monthlyAttendanceCounts.first(where: { $0.monthName == monthName }) {
                                            selectedMonth = selected
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 250)
            .padding()
        }
        .onAppear {
            loadAvailableYears()
            loadMonthlyAttendanceCounts()
        }
    }
    
    private func loadAvailableYears() {
        var yearsSet = Set<Int>()
        
        let filteredStudents = students.filter { $0.course == courseType }
        
        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let year = Calendar.current.component(.year, from: attendance.date)
                yearsSet.insert(year)
            }
        }
        
        availableYears = Array(yearsSet).sorted()
        
        if !availableYears.contains(selectedYear) {
            selectedYear = availableYears.first ?? Calendar.current.component(.year, from: Date())
        }
    }
    
    private func loadMonthlyAttendanceCounts() {
        var attendanceCounts = Array(repeating: 0, count: 12)
        
        let filteredStudents = students.filter { $0.course == courseType }
        
        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let attendanceYear = Calendar.current.component(.year, from: attendance.date)
                if attendanceYear == selectedYear {
                    let month = Calendar.current.component(.month, from: attendance.date)
                    attendanceCounts[month - 1] += 1
                }
            }
        }
        
        monthlyAttendanceCounts = attendanceCounts.enumerated().map { index, count in
            SumMonthlyAttendance(month: index + 1, count: count)
        }
    }
}

struct SumMonthlyAttendance: Identifiable, Hashable {
    var id: Int { month }
    var month: Int
    var count: Int
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: month)) ?? Date()
        return formatter.string(from: date)
    }
}

struct DayDetail: Identifiable {
    var id = UUID()
    var date: Date
    var count: Int

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd.MM"
        return formatter.string(from: date)
    }
}


extension AttendanceSummaryView {
    private func dailyDetails(for month: SumMonthlyAttendance) -> [DayDetail] {
        let calendar = Calendar.current
        let year = selectedYear
        let filteredStudents = students.filter { $0.course == courseType }

        var attendanceMap: [Date: Int] = [:]

        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let date = attendance.date
                let dateComponents = calendar.dateComponents([.year, .month, .weekday], from: date)

                if dateComponents.year == year &&
                    dateComponents.month == month.month &&
                    [2, 4, 6].contains(dateComponents.weekday ?? 0) {
                    let day = calendar.startOfDay(for: date)
                    attendanceMap[day, default: 0] += 1
                }
            }
        }

        return attendanceMap.map { (date, count) in
            DayDetail(date: date, count: count)
        }
        .sorted(by: { $0.date < $1.date })
    }
}
