//
//  Homeview.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: [SortDescriptor(\Student.name), SortDescriptor(\Student.firstName)]) var students: [Student]
    @Query var workoutPlans: [WorkoutPlan]
    @Query var allPreferences: [DrillPreference]
    @Query(sort: \WorkoutPlan.date, order: .reverse) var recentPlans: [WorkoutPlan]
    
    @State private var selectedDate = Date()
    @State private var showingDateList = false
    
    @State private var isAttendanceExpanded = false
    
    // AI Integration
    @State private var isGeneratingWorkout = false
    @State private var isRegenerating = false
    @State private var showingRegenerateSheet = false
    @State private var isEditingPlan = false
    @State private var editedPlanContent = ""
    @State private var selectedFocus: TrainingFocus = .kumite
    @State private var errorMessage: String?
    @State private var showingError = false
    @AppStorage("workout_duration") private var duration = 60
    private let openAIService = OpenAIService()
    
    // Training Day Settings
    @AppStorage("trainingDay_2") private var monday = false
    @AppStorage("trainingDay_3") private var tuesday = false
    @AppStorage("trainingDay_4") private var wednesday = false
    @AppStorage("trainingDay_5") private var thursday = false
    @AppStorage("trainingDay_6") private var friday = false
    @AppStorage("trainingDay_7") private var saturday = false
    @AppStorage("trainingDay_1") private var sunday = false
    
    // Helper to find plan for selected date
    var planForSelectedDate: WorkoutPlan? {
        workoutPlans.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // 1. Date Navigation Area (Sticky Top)
                    HStack {
                        Spacer()
                        
                        Button(action: { jumpToTrainingDay(direction: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { showingDateList = true }) {
                            Text(formattedDate(selectedDate))
                                .font(.headline)
                                .frame(minWidth: 150)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                        .sheet(isPresented: $showingDateList) {
                            TrainingDayPickerView(selectedDate: $selectedDate, isPresented: $showingDateList, checkTrainingDay: { date in
                                isTrainingDay(date: date)
                            })
                            .presentationDetents([.medium, .large])
                        }
                        
                        Button(action: { jumpToTrainingDay(direction: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    // 2. Scrollable Content: Workout Plan
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // --- SECTION: WORKOUT PLAN ---
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    Text("Trainingsplan")
                                        .font(.title2).bold()
                                    Spacer()
                                    
                                    if planForSelectedDate != nil {
                                        if isEditingPlan {
                                            Button("Speichern") {
                                                saveEditedPlan()
                                            }
                                            .bold()
                                            .foregroundColor(.blue)
                                        } else {
                                            Menu {
                                                Button("Bearbeiten", action: startEditingPlan)
                                                Button("Neu Generieren", role: .destructive) {
                                                    showingRegenerateSheet = true
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle")
                                                    .font(.title2)
                                                    .foregroundColor(.purple)
                                            }
                                        }
                                    }
                                }
                                
                                if let plan = planForSelectedDate {
                                    if isEditingPlan {
                                        TextEditor(text: $editedPlanContent)
                                            .frame(minHeight: 300)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    } else {
                                        StructuredPlanView(content: plan.content)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                    }
                                } else {
                                    // No Plan State
                                    if isGeneratingWorkout {
                                        ProgressView("Generiere Plan...")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        VStack(spacing: 16) {
                                            Text("Kein Trainingsplan für heute.")
                                                .foregroundColor(.secondary)
                                            
                                            Picker("Fokus", selection: $selectedFocus) {
                                                ForEach(TrainingFocus.allCases, id: \.self) { focus in
                                                    Text(focus.rawValue).tag(focus)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                            .padding(.horizontal)
                                            
                                            Button(action: generateWorkout) {
                                                Text("Jetzt generieren")
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.purple)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                            
                            // Extra space at bottom for the expandable sheet
                            Spacer(minLength: 100)
                        }
                        .padding(.top)
                    }
                }
                
                // Expandable Attendance Section (Restored)
                VStack(spacing: 0) {
                    // Header / Toggle Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isAttendanceExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Anwesenheiten")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: isAttendanceExpanded ? "chevron.down" : "chevron.up")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15, corners: [.topLeft, .topRight])
                    }
                    
                    if isAttendanceExpanded {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(students) { student in
                                    StudentAttendanceRow(student: student, date: selectedDate)
                                }
                            }
                            .padding()
                        }
                        .frame(maxHeight: 300) // Limit height
                        .background(Color(.systemBackground))
                    }
                }
                .shadow(radius: 5)
                .padding(.horizontal)
            }
            .navigationTitle("ShinDoKan Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingRegenerateSheet) {
                NavigationStack {
                    Form {
                        Section {
                            Text("Der aktuelle Plan wird unwiderruflich überschrieben.")
                                .foregroundColor(.secondary)
                        }
                        
                        Section(header: Text("Fokus für neuen Plan")) {
                            Picker("Fokus", selection: $selectedFocus) {
                                ForEach(TrainingFocus.allCases, id: \.self) { focus in
                                    Text(focus.rawValue).tag(focus)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Section {
                            Button("Plan Neu Generieren") {
                                showingRegenerateSheet = false
                                Task { await regeneratePlan() }
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .navigationTitle("Plan erneuern")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                showingRegenerateSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .overlay {
                if isRegenerating {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Aktualisiere...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .alert("Fehler", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "Ein unbekannter Fehler ist aufgetreten.")
        })
        }

    
    // MARK: - Logic
    
    private func generateWorkout() {
        isGeneratingWorkout = true
        Task {
            do {
                let content = try await openAIService.generateWorkoutPlan(
                    durationMinutes: duration,
                    preferences: allPreferences,
                    recentPlans: recentPlans,
                    focus: selectedFocus
                )
                await MainActor.run {
                    let newPlan = WorkoutPlan(date: selectedDate, content: content)
                    modelContext.insert(newPlan)
                    isGeneratingWorkout = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingWorkout = false
                    handleError(error)
                }
            }
        }
    }
    
    private func regeneratePlan() async {
        guard let plan = planForSelectedDate else { return }
        isRegenerating = true
        do {
            let newContent = try await openAIService.generateWorkoutPlan(
                durationMinutes: duration,
                preferences: allPreferences,
                recentPlans: recentPlans,
                focus: selectedFocus
            )
            await MainActor.run {
                plan.content = newContent
                try? modelContext.save()
                isRegenerating = false
            }
        } catch {
            await MainActor.run {
                isRegenerating = false
                handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let aiError = error as? OpenAIService.AIError {
            switch aiError {
            case .missingApiKey:
                errorMessage = "API Key fehlt. Bitte in den Einstellungen hinterlegen."
            case .networkError(let err):
                errorMessage = "Netzwerkfehler: \(err.localizedDescription)"
            case .invalidResponse:
                errorMessage = "Ungültige Antwort vom Server."
            case .decodingError:
                errorMessage = "Fehler beim Verarbeiten der Antwort."
            }
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
    
    private func startEditingPlan() {
        guard let plan = planForSelectedDate else { return }
        editedPlanContent = plan.content
        isEditingPlan = true
    }
    
    private func saveEditedPlan() {
        guard let plan = planForSelectedDate else { return }
        plan.content = editedPlanContent
        try? modelContext.save()
        isEditingPlan = false
    }
    
    // MARK: - Helper Functions (Date & Training Day)
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd.MM.yy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    private func jumpToTrainingDay(direction: Int) {
        let calendar = Calendar.current
        var currentDate = selectedDate
        var checks = 0
        while checks < 365 {
            currentDate = calendar.date(byAdding: .day, value: direction, to: currentDate) ?? currentDate
            if isTrainingDay(date: currentDate) {
                selectedDate = currentDate
                return
            }
            checks += 1
        }
    }
    
    private func isTrainingDay(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: return false
        }
    }
}

struct TrainingDayPickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let checkTrainingDay: (Date) -> Bool
    
    @State private var availableDates: [Date] = []
    
    var body: some View {
        NavigationStack {
            List(availableDates, id: \.self) { date in
                Button(action: {
                    selectedDate = date
                    isPresented = false
                }) {
                    HStack {
                        Text(formatDate(date))
                            .foregroundColor(.primary)
                        Spacer()
                        if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Datum wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                generateDates()
            }
        }
    }
    
    private func generateDates() {
        let calendar = Calendar.current
        let today = Date()
        // Range: Today to -1 year
        guard let endDate = calendar.date(byAdding: .year, value: -1, to: today) else { return }
        
        var date = today
        var validDates: [Date] = []
        
        // Loop backwards from today to 1 year ago
        while date >= endDate {
            if checkTrainingDay(date) {
                validDates.append(date)
            }
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        
        availableDates = validDates
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd.MM.yy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
}

struct StudentAttendanceRow: View {
    let student: Student
    let date: Date
    @Environment(\.modelContext) var modelContext
    
    var isPresent: Bool {
        student.attendances.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.isPresent }
    }
    
    var body: some View {
        Button(action: toggleAttendance) {
            HStack {
                Text("\(student.firstName) \(student.name)")
                    .foregroundColor(.primary)
                    .bold()
                Spacer()
                if isPresent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(isPresent ? Color.green.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPresent ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func toggleAttendance() {
        let calendar = Calendar.current
        
        // Check if attendance exists for this day
        if let existingIndex = student.attendances.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // Remove existing
            let attendance = student.attendances[existingIndex]
            student.attendances.remove(at: existingIndex)
            modelContext.delete(attendance)
        } else {
            // Add new
            let newAttendance = Attendance(date: date, isPresent: true, student: student)
            student.attendances.append(newAttendance)
            modelContext.insert(newAttendance)
        }
    }
}

// Extension needed for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    HomeView()
}



struct StructuredPlanView: View {
    let content: String
    
    var lines: [String] {
        content.components(separatedBy: .newlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 4)
                } else if line.hasPrefix("# ") {
                    Text(parseMarkdown(String(line.dropFirst(2))))
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                } else if line.hasPrefix("## ") {
                    Text(parseMarkdown(String(line.dropFirst(3))))
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                } else if line.hasPrefix("### ") {
                    Text(parseMarkdown(String(line.dropFirst(4))))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                        .padding(.top, 2)
                } else {
                    Text(parseMarkdown(line))
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            let attributedString = try AttributedString(markdown: text)
            // Ensure font size consistency if markdown parser overrides it,
            // though usually it only affects traits like bold/italic.
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}
