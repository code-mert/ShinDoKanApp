//
//  StudentListView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext //verwendet das "modelcontext" aus der Umgebung, um auf das Datenmodell zuzugreifen. Dies wird für Datenoperationen verwendet.
    @Query(sort: \Student.name) private var students: [Student] // Definiert Abfrage, die eine sortierte Liste von 'Student'-Objekten nach Ihrem 'name' enthält
    @State private var isPresentingAddStudentView = false //Verwaltet Zustand, ob das 'AddStudentView' Formular angezeigt wird oder nicht
    
    @State private var showAlert = false
    @State private var filterText = ""
    @State private var selectedCourse: Course? = nil
    @State private var studentToDelete: Student?
    
    var body: some View {
        NavigationStack { // Erstellt Navigation um zwischen verschiedenen Ansichten zu wechseln
            VStack {
                VStack {
                    TextField("Name oder Alter suchen", text: $filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Picker("Kurs filtern", selection: $selectedCourse) {
                        Text("Alle").tag(nil as Course?)
                        ForEach(Course.allCases, id: \.self) { course in
                            Text(course.rawValue).tag(course as Course?)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                List { //Erstellung einer Liste
                    ForEach(students.filter {
                        (filterText.isEmpty ||
                         "\($0.firstName) \($0.name)".localizedCaseInsensitiveContains(filterText) ||
                         String($0.birthDate.age()).contains(filterText))
                        && (selectedCourse == nil || $0.course == selectedCourse)
                    }) { student in //Iteriert über die gefilterte 'student' Liste und erstellt für jeden 'student' ein Listenelement
                        NavigationLink(destination: StudentDetailView(student: student)) {
                            VStack(alignment: .leading) { // Stapelt enthaltene Ansichten vertikal mit linker Ausrichtung
                                Text("\(student.firstName) \(student.name)") // Zeigt vollständigen Namen an
                                    .font(.headline)
                                Text("Alter: \(student.birthDate.age())")
                                Text("Kurs: \(String(describing: student.course.rawValue))")
                            }
                        }
                    }
                    .onDelete(perform: prepareToDeleteStudent)                          // Löschen durch Wischgeste
                }
            }
            .toolbar { // Fügt Navigationsleiste ein Toolbar Element hinzu
                ToolbarItem(placement: .topBarTrailing) {                                // Platziert das ToolbarElement am rechten Rand der Navigationsleiste
                    HStack {
                        Button(action: {                                            // Knopf öffnet Formular 'AddStudentView'
                        isPresentingAddStudentView = true
                    }) {
                        Image(systemName: "plus")                                   // Symbol auf dem Knopf
                        }
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddStudentView) {                      // Zeigt ein modales Formular an, wenn isPresentingAddStudentView wahr ist.
                AddStudentView() // Formular zum Hinzufügen
                    .environment(\.modelContext, modelContext)                      // Stellt sicher, dass AddStudentView denselben modelContext verwendet
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Löschen bestätigen"),
                    message: Text("Bist du sicher, dass \(studentToDelete?.firstName ?? "")\(studentToDelete?.name ?? "diesen Schüler") löschen möchten?"),
                    primaryButton: .destructive(Text("Löschen")) {
                        if let student = studentToDelete {
                            deleteStudent(student: student)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationTitle("Schüler")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func prepareToDeleteStudent(at offsets: IndexSet) {                     // IndexSet gibt an, welche Zeilen in der Liste gelöscht werden soll.
        if let index = offsets.first {
            studentToDelete = students[index]                                       // Eine der Zahlen aus dem IndexSet, die auf bestimmten Schüler in der "students" Liste zeigt.
            showAlert = true
        }
    }
    
    private func deleteStudent(student: Student) {                                  // Funktion Delete Student
            modelContext.delete(student)                                            // Löscht den Schüler aus dem Datenmodell
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving context after delete: \(error)")
        }
    }
}

extension DateFormatter { // Erweiterung von DateFormatter
    static var shortDate: DateFormatter { // Erstellt statischen DateFormatter der ein kurzes Datenformat verwendet
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

#Preview {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: configuration)
    
    let context = container.mainContext
    
    let dummyStudent = Student(
        name: "Mustermann",
        firstName: "Max",
        birthDate: Calendar.current.date(from: DateComponents(year:2010, month:5, day:15))!,
        belt: .kyu9,
        weight: "35",
        lastExamDate: Calendar.current.date(from: DateComponents(year:2024, month:3, day:20))!,
        course: .beginner
    )
    context.insert(dummyStudent)

    let dummyStudent2 = Student(
        name: "Müller",
        firstName: "Anna",
        birthDate: Calendar.current.date(from: DateComponents(year:2011, month:8, day:23))!,
        belt: .kyu8,
        weight: "32",
        lastExamDate: Calendar.current.date(from: DateComponents(year:2024, month:4, day:10))!,
        course: .advanced
    )

    let dummyStudent3 = Student(
        name: "Schmidt",
        firstName: "Lukas",
        birthDate: Calendar.current.date(from: DateComponents(year:2009, month:2, day:5))!,
        belt: .kyu6,
        weight: "40",
        lastExamDate: Calendar.current.date(from: DateComponents(year:2023, month:11, day:30))!,
        course: .beginner
    )

    context.insert(dummyStudent2)
    context.insert(dummyStudent3)
    
    return StudentListView()
        .modelContainer(container)
}
