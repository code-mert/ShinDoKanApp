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
    
    @State private var selectedDate = Date()
    @State private var showingDateList = false
    @State private var isAttendanceExpanded = false
    
    // Training Day Settings (1=Sun, 2=Mon...7=Sat)
    @AppStorage("trainingDay_2") private var monday = false
    @AppStorage("trainingDay_3") private var tuesday = false
    @AppStorage("trainingDay_4") private var wednesday = false
    @AppStorage("trainingDay_5") private var thursday = false
    @AppStorage("trainingDay_6") private var friday = false
    @AppStorage("trainingDay_7") private var saturday = false
    @AppStorage("trainingDay_1") private var sunday = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main Content
                VStack {
                    // Custom Date Navigation Area
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            jumpToTrainingDay(direction: -1)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showingDateList = true
                        }) {
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
                        
                        Button(action: {
                            jumpToTrainingDay(direction: 1)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    // Dashboard Content
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            Image(systemName: "house.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.orange)
                                .opacity(0.5)
                            
                            Text("ShinDoKan Dashboard")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                    }
                    
                    Spacer()
                }
                
                // Expandable Attendance Section
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
            .navigationTitle("Shindokan App")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                #if DEBUG
                createDemoStudentsIfNeeded(modelContext: modelContext)
                #endif
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd.MM.yy" // Montag, 15.12.25
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }
    
    private func jumpToTrainingDay(direction: Int) {
        let calendar = Calendar.current
        var currentDate = selectedDate
        
        // Safety break to prevent infinite loops if NO days are selected
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
        // Range: -1 year to +1 year
        guard let startDate = calendar.date(byAdding: .year, value: -1, to: today),
              let endDate = calendar.date(byAdding: .year, value: 1, to: today) else { return }
        
        var date = startDate
        var validDates: [Date] = []
        
        while date <= endDate {
            if checkTrainingDay(date) {
                validDates.append(date)
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
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
                Text("\(student.name), \(student.firstName)")
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
