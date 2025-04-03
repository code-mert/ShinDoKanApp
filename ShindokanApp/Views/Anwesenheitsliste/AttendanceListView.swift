import SwiftUI
import SwiftData

struct AttendanceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.name) private var allStudents: [Student]
    @State private var selectedDate: Date = Date()
    
    var courseType: Course
    
    var filteredStudents: [Student] {
        allStudents.filter { $0.course == courseType}
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    Spacer()
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal) // nur horizontal um Abstand zwischen Titel und DatePicker kleiner zu machen
                List {
                    ForEach(filteredStudents) { student in
                        AttendanceRow(student: student, date: selectedDate)
                            .frame(maxWidth: .infinity) // Maximiert die Breite
                    }
                }
                .listStyle(.plain)
                .id(selectedDate)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: AttendanceSummaryView(courseType: courseType)) {
                        Image(systemName: "info.circle")
                        .font(.title2)}
            }
        }
    }
}

struct AttendanceRow: View {
    var student: Student
    var date: Date
    
    @Environment(\.modelContext) private var modelContext
    @State private var isPresent: Bool = false

    var body: some View {
        HStack {
            // Bereich für den Namen mit Hintergrundfarbe
            Text("\(student.firstName) \(student.name)")
                .font(.headline)
                .padding(.vertical, 12) // Vertikaler Abstand
                .padding(.horizontal, 8) // Horizontaler Abstand
                .frame(maxWidth: .infinity, alignment: .leading) // Text linksbündig, nimmt maximalen Platz ein
                .background(isPresent ? Color.green.opacity(0.3) : Color.clear) // Grüne Markierung
                .cornerRadius(10)
                .onTapGesture {
                    toggleAttendance()
                }
                .onAppear {
                    loadAttendance()
                }
                
            // Navigations-Button mit fester Breite
            NavigationLink(destination: AttendanceSingleChartView(student: student)) {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundColor(.orange)
                }
                .frame(width: 40, height: 40) // Feste Größe des Buttons
                .padding(.trailing, 8) // Abstand rechts
            }
            .frame(maxWidth: .infinity) // Zeile füllt die gesamte Breite aus
            .onChange(of: date) {
                loadAttendance()
            }
            .navigationTitle("Anwesenheitsliste")
        }

    private func loadAttendance() {
        // Lade die Anwesenheitsdaten für das aktuelle Datum und den Schüler
        if let existingAttendance = student.attendances.first(where: {Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            DispatchQueue.main.async {
                self.isPresent = existingAttendance.isPresent
            }
        } else {
            DispatchQueue.main.async {
                self.isPresent = false
            }
        }
    }

    private func toggleAttendance() {
        // Prüfe, ob es bereits eine Anwesenheit für das aktuelle Datum gibt
        if let existingAttendance = student.attendances.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            existingAttendance.isPresent.toggle()
            isPresent = existingAttendance.isPresent
        } else {
            // Erstelle eine neue Anwesenheit, wenn sie noch nicht existiert
            let newAttendance = Attendance(date: date, isPresent: true, student: student)
            student.attendances.append(newAttendance)
            modelContext.insert(newAttendance)
            isPresent = true
        }
        try? modelContext.save()
    }
}

extension DateFormatter {
    static var weekdayDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter
    }

    static var fullDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter
    }
}
