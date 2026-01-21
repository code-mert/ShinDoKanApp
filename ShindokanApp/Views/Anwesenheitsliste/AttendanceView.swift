import SwiftUI
import SwiftData

struct AttendanceView: View {
    @Query var students: [Student]
    @Query var allAttendances: [Attendance]

    @State private var selectedCourse: CourseFilter = .all
    @State private var sortOrder: SortOrder = .descending
    @State private var timeRange: TimeRange = .allTime

    enum CourseFilter: String, CaseIterable, Identifiable {
        case all = "Alle"
        case beginner = "Anfänger"
        case advanced = "Fortgeschritten"
        
        var id: String { rawValue }
    }
    
    enum SortOrder: String, CaseIterable, Identifiable {
        case descending = "Meiste Anwesenheit"
        case ascending = "Wenigste Anwesenheit"
        
        var id: String { rawValue }
    }
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case allTime = "Gesamt"
        case currentYear = "Aktuelles Jahr"
        case currentMonth = "Aktueller Monat"
        
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Durchschnittliche Anwesenheit")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f", averageAttendanceCount))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                ForEach(sortedStudents) { student in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(student.firstName) \(student.name)")
                                .font(.headline)
                            Text(student.course.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(attendancePercentage(for: student))%")
                                .font(.subheadline)
                                .bold()
                            
                            ProgressView(value: attendanceProgress(for: student))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(width: 100)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Statistik")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Kurs", selection: $selectedCourse) {
                            ForEach(CourseFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        
                        Picker("Zeitraum", selection: $timeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        
                        Picker("Sortierung", selection: $sortOrder) {
                            ForEach(SortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    // MARK: - Average Attendance Calculation
    
    private var averageAttendanceCount: Double {
        let filteredStudents = students.filter { student in
            switch selectedCourse {
            case .all: return true
            case .beginner: return student.course == .beginner
            case .advanced: return student.course == .advanced
            }
        }
        
        var totalPresent = 0
        for student in filteredStudents {
            let presentCount = student.attendances.filter {
                $0.isPresent && isInTimeRange($0.date)
            }.count
            totalPresent += presentCount
        }
        
        // Use totalTrainingSessions (actual days with data) instead of theoretical calendar days
        let sessionCount = totalTrainingSessions
        return sessionCount > 0 ? Double(totalPresent) / Double(sessionCount) : 0.0
    }
    
    // Berechnet die gesamten Trainingseinheiten im gewählten Zeitraum
    private var totalTrainingSessions: Int {
        let filteredDates = allAttendances
            .filter { attendance in
                // 1. Check strict presence
                guard attendance.isPresent else { return false }
                
                // 2. Check Time Range
                guard isInTimeRange(attendance.date) else { return false }
                
                // 3. Check Course Filter
                switch selectedCourse {
                case .all:
                    return true
                case .beginner:
                    return attendance.student.course == .beginner
                case .advanced:
                    return attendance.student.course == .advanced
                }
            }
            .map { Calendar.current.startOfDay(for: $0.date) }
        
        return Set(filteredDates).count
    }
    
    // Sortierte und gefilterte Liste der Schüler
    private var sortedStudents: [Student] {
        let filteredByCourse = students.filter { student in
            switch selectedCourse {
            case .all: return true
            case .beginner: return student.course == .beginner
            case .advanced: return student.course == .advanced
            }
        }
        
        return filteredByCourse.sorted {
            let p1 = attendancePercentageValue(for: $0)
            let p2 = attendancePercentageValue(for: $1)
            
            switch sortOrder {
            case .descending: return p1 > p2
            case .ascending: return p1 < p2
            }
        }
    }
    
    // Hilfsfunktion: Check ob Datum im Range ist
    private func isInTimeRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .allTime:
            return true
        case .currentYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .currentMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
    }
    
    // Berechnet den Prozentwert als Double
    private func attendancePercentageValue(for student: Student) -> Double {
        guard totalTrainingSessions > 0 else { return 0.0 }
        
        let presentCount = student.attendances.filter {
            $0.isPresent && isInTimeRange($0.date)
        }.count
        
        return Double(presentCount) / Double(totalTrainingSessions) * 100
    }
    
    // Gibt den formatierten String zurück
    private func attendancePercentage(for student: Student) -> String {
        return String(format: "%.0f", attendancePercentageValue(for: student))
    }
    
    // Gibt den Wert für die ProgressView zurück
    private func attendanceProgress(for student: Student) -> Double {
        guard totalTrainingSessions > 0 else { return 0.0 }
        
        let presentCount = student.attendances.filter {
            $0.isPresent && isInTimeRange($0.date)
        }.count
        
        return Double(presentCount) / Double(totalTrainingSessions)
    }
}
