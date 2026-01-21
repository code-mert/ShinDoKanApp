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
        ScrollView {
            VStack {
                Text("Kurs: \(courseType.rawValue)")
                    .font(.title)
                    .padding(.top)
                
                Text(String(format: "Durchschnittliche Anwesenheit: %.1f", averageAttendance))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
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
                
                if let selected = selectedMonth {
                    Chart(dailyDetails(for: selected)) { item in
                        BarMark(
                            x: .value("Tag", item.label),
                            y: .value("Anwesende", item.count)
                        )
                        .foregroundStyle(.orange)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine().foregroundStyle(.clear)
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXScale(range: .plotDimension(padding: 20))
                    .frame(height: 300)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .onAppear {
                loadAvailableYears()
                loadMonthlyAttendanceCounts()
            }
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
    
    private var averageAttendance: Double {
        let filteredStudents = students.filter { $0.course == courseType }
        var totalAttendance = 0
        
        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let calendar = Calendar.current
                let year = calendar.component(.year, from: attendance.date)
                
                if year == selectedYear {
                    if let selectedMonth = selectedMonth {
                        if calendar.component(.month, from: attendance.date) == selectedMonth.month {
                            totalAttendance += 1
                        }
                    } else {
                        totalAttendance += 1
                    }
                }
            }
        }
        
        let sessions = calculateTotalSessions(year: selectedYear, month: selectedMonth?.month)
        return sessions > 0 ? Double(totalAttendance) / Double(sessions) : 0.0
    }
    
    private func calculateTotalSessions(year: Int, month: Int?) -> Int {
        let calendar = Calendar.current
        var count = 0
        let today = Date()
        
        let startComponents: DateComponents
        let endComponents: DateComponents
        
        if let month = month {
            startComponents = DateComponents(year: year, month: month, day: 1)
            endComponents = DateComponents(year: year, month: month + 1, day: 0)
        } else {
            startComponents = DateComponents(year: year, month: 1, day: 1)
            endComponents = DateComponents(year: year, month: 12, day: 31)
        }
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else { return 1 }
        
        var currentDate = startDate
        
        while currentDate <= endDate && currentDate <= today {
            let weekday = calendar.component(.weekday, from: currentDate)
            // 2 = Monday, 4 = Wednesday
            if [2, 4].contains(weekday) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        return count
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

    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        let hiddenDate = formatter.string(from: date)
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "E"
        let weekday = weekdayFormatter.string(from: date)
        return "\(weekday)\u{200B}\(hiddenDate)" // Zero-width space trennt unsichtbar
    }
}


extension AttendanceSummaryView {
    private func dailyDetails(for month: SumMonthlyAttendance) -> [DayDetail] {
        let calendar = Calendar.current
        let year = selectedYear
        let filteredStudents = students.filter { $0.course == courseType }

        let components = DateComponents(year: year, month: month.month)
        guard let startOfMonth = calendar.date(from: components) else { return [] }

        var dates: [Date] = []
        var currentDate = startOfMonth

        while calendar.component(.month, from: currentDate) == month.month {
            let weekday = calendar.component(.weekday, from: currentDate)
            if [2, 4].contains(weekday) {
                dates.append(calendar.startOfDay(for: currentDate))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        var attendanceMap: [Date: Int] = [:]
        for student in filteredStudents {
            for attendance in student.attendances where attendance.isPresent {
                let date = calendar.startOfDay(for: attendance.date)
                if calendar.component(.year, from: date) == year &&
                    calendar.component(.month, from: date) == month.month &&
                    [2, 4].contains(calendar.component(.weekday, from: date)) {
                    attendanceMap[date, default: 0] += 1
                }
            }
        }

        return dates.map { date in
            DayDetail(date: date, count: attendanceMap[date, default: 0])
        }
    }
}
