import SwiftUI
import SwiftData

struct StudentAttendanceCalendarView: View {
    let student: Student
    
    @State private var currentMonth: Date = Date()
    
    // Calendar tools
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month Navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(monthYearString(from: currentMonth))
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Days of the Week Header
                HStack {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 15) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isAttendance: isPresentOn(date)
                            )
                        } else {
                            // Empty cell for offset
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Divider()
                    .padding(.horizontal)
                
                // Stats
                VStack(spacing: 16) {
                    HStack {
                        Text("Anwesenheiten in diesem Monat:")
                        Spacer()
                        Text("\(attendancesInCurrentMonth())")
                            .bold()
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Anwesenheiten insgesamt:")
                        Spacer()
                        Text("\(totalAttendances())")
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .font(.headline)
                
                Spacer()
            }
        }
        .navigationTitle("\(student.firstName) \(student.name)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Logic
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private var weekdaySymbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "de_DE")
        let symbols = calendar.shortWeekdaySymbols
        
        // Force Monday start regardless of calendar locale defaults
        // Sunday is usually index 0, Monday index 1
        return Array(symbols[1...6]) + [symbols[0]]
    }
    
    // Generates an array of dates for the month, with nils padding the start
    private func daysInMonth() -> [Date?] {
        guard let daysRange = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let numberOfDays = daysRange.count
        
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        // Find weekday of first day (1 = Sunday, 2 = Monday, ... 7 = Saturday)
        // We want Monday = 1, Tuesday = 2, ... Sunday = 7
        // Calendar defaults to Sunday = 1, Monday = 2
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday == 1 ? 6 : firstWeekday - 2 // Adjust for Monday start
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        
        for dayOffset in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isPresentOn(_ date: Date) -> Bool {
        return student.attendances.contains { attendance in
            attendance.isPresent && calendar.isDate(attendance.date, inSameDayAs: date)
        }
    }
    
    private func totalAttendances() -> Int {
        return student.attendances.filter { $0.isPresent }.count
    }
    
    private func attendancesInCurrentMonth() -> Int {
        return student.attendances.filter { attendance in
            attendance.isPresent && calendar.isDate(attendance.date, equalTo: currentMonth, toGranularity: .month)
        }.count
    }
}

struct DayCell: View {
    let date: Date
    let isAttendance: Bool
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Text(dayString)
            .font(.system(size: 16))
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(isAttendance ? Color.blue.opacity(0.8) : Color.clear)
            .foregroundColor(isAttendance ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isAttendance ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
