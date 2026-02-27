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
                        Text(String(format: "%.1f", calculatedAverage))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                if sortedStudentIDs.isEmpty {
                    // Optional: Loading state or just empty
                    // Since it runs in background, maybe list updates shortly after.
                }
                
                ForEach(displayStudents) { student in
                    NavigationLink(destination: StudentAttendanceCalendarView(student: student)) {
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
            // Trigger calculation when view appears or filters change
            .task(id: selectedCourse) { await calculateStats() }
            .task(id: timeRange) { await calculateStats() }
            .task(id: sortOrder) { await calculateStats() }
            // Observe data changes if possible (SwiftData query updates might trigger this whole view rebuilt, recalculating on appear)
            .onAppear {
                 Task { await calculateStats() }
            }
        }
    }
    
    // MARK: - Average Attendance Calculation
    
    // MARK: - Helper Structs for Background Calculation
    
    private struct StudentData: Identifiable, Sendable {
        let id: PersistentIdentifier
        let firstName: String
        let name: String
        let course: Course
        let attendanceDates: [Date]
    }
    
    // MARK: - State for Calculations
    @State private var calculatedAverage: Double = 0.0
    @State private var sortedStudentIDs: [PersistentIdentifier] = []
    @State private var studentPercentages: [PersistentIdentifier: Double] = [:]
    
    // MARK: - Calculation Logic
    
    private func calculateStats() async {
        // 1. Prepare Data on Main Actor (Fast, just mapping)
        let currentCourse = selectedCourse
        let currentTimeRange = timeRange
        let currentSortOrder = sortOrder
        
        let studentDataList: [StudentData] = students.map { student in
            StudentData(
                id: student.persistentModelID,
                firstName: student.firstName,
                name: student.name,
                course: student.course,
                attendanceDates: student.attendances.filter { $0.isPresent }.map { $0.date }
            )
        }
        
        // Use a detached task for heavy logic
        let result = await Task.detached(priority: .userInitiated) {
            // Helper function inside Task
            func isInTimeRange(_ date: Date) -> Bool {
                let calendar = Calendar.current
                let now = Date()
                switch currentTimeRange {
                case .allTime: return true
                case .currentYear: return calendar.isDate(date, equalTo: now, toGranularity: .year)
                case .currentMonth: return calendar.isDate(date, equalTo: now, toGranularity: .month)
                }
            }
            
            // 2. Filter Students
            let filteredStudents = studentDataList.filter { student in
                switch currentCourse {
                case .all: return true
                case .beginner: return student.course == .beginner
                case .advanced: return student.course == .advanced
                }
            }
            
            // 3. Calculate Total Sessions (Denominator)
            // We need to look at ALL relevant attendance dates across ALL filtered students
            var allRelevantDates = Set<Date>()
            
            // Optimization: If we just need unique dates, we can collect them from the filtered students
            // But we must also respect the course filter for the DENOMINATOR.
            // Wait, the previous logic filtered `allAttendances`.
            // If we only have `students`, we can iterate their attendances.
            // Since `allAttendances` is just the union of all student attendances, using `students` is fine.
            // AND faster because we already mapped it.
            
            // We need to iterate ALL students (not just filtered ones?)
            // No, the denominator logic was: "filter all attendances... switch selectedCourse".
            // So if `selectedCourse` is Beginner, we only count days where a Beginner was present.
            // Our `filteredStudents` list already contains only Beginners.
            // So iterating `filteredStudents` attendances is correct.
            
            for student in filteredStudents {
                for date in student.attendanceDates {
                    if isInTimeRange(date) {
                        allRelevantDates.insert(Calendar.current.startOfDay(for: date))
                    }
                }
            }
            
            let totalSessions = allRelevantDates.count
            
            // 4. Calculate Stats per Student
            var stats: [PersistentIdentifier: Double] = [:]
            var totalPresent = 0
            
            for student in filteredStudents {
                let presentCount = student.attendanceDates.filter { isInTimeRange($0) }.count
                totalPresent += presentCount
                
                let percentage = totalSessions > 0 ? Double(presentCount) / Double(totalSessions) * 100 : 0.0
                stats[student.id] = percentage
            }
            
            // 5. Calculate Average
            let average = totalSessions > 0 ? Double(totalPresent) / Double(totalSessions) : 0.0
            
            // 6. Sort
            let sortedIDs = filteredStudents.sorted { s1, s2 in
                let p1 = stats[s1.id] ?? 0
                let p2 = stats[s2.id] ?? 0
                
                switch currentSortOrder {
                case .descending: return p1 > p2
                case .ascending: return p1 < p2
                }
            }.map { $0.id }
            
            return (average, sortedIDs, stats)
        }.value
        
        // Update UI on Main Actor
        await MainActor.run {
            self.calculatedAverage = result.0
            self.sortedStudentIDs = result.1
            self.studentPercentages = result.2
        }
    }
    
    // MARK: - UI Configuration
    
    private var displayStudents: [Student] {
        // Re-construct the list from IDs to maintain SwiftData observation
        // Use the sorted IDs to order the `students` array
        
        // Map current students to dictionary for O(1) lookup
        let studentMap = Dictionary(uniqueKeysWithValues: students.map { ($0.persistentModelID, $0) })
        
        return sortedStudentIDs.compactMap { studentMap[$0] }
    }
    
    private func getPercentage(for student: Student) -> Double {
        return studentPercentages[student.persistentModelID] ?? 0.0
    }
    
    private func attendancePercentage(for student: Student) -> String {
        return String(format: "%.0f", getPercentage(for: student))
    }
    
    private func attendanceProgress(for student: Student) -> Double {
        return getPercentage(for: student) / 100.0
    }
}
