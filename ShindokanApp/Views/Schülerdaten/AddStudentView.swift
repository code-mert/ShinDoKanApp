//
//  AddStudentView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct AddStudentView: View { // Definiert neue Ansicht 'AddStudentView'
    @Environment(\.dismiss) var dismiss // Umgebungsvariable zum Schließen der aktuellen Ansicht
    @Environment(\.modelContext) private var modelContext // Verwendet das modelcontext aus der Umgebung, um auf das Datenmodell zuzugreifen
    @State var name: String = ""
    @State var firstName: String = ""
    @State var birthDate: Date = Date()
    @State var belt: BeltGrade = .kyu9
    @State var weight: String = ""
    @State var lastExamDate: Date = Date() // Speichern der Eingabefelder
    @State var course: Course = .beginner
    
    var studentToEdit: Student?
    
    var body: some View {
        NavigationView {
            Form { // Erstellt Formular mit Eingabefeldern
                Section(header: Text("Schüler Daten")) {
                    TextField("Vorname", text: $firstName)
                    TextField("Name", text: $name)
                    
                    DatePicker("Geburtsdatum", selection: $birthDate, displayedComponents: .date)
                    Picker("Kyu - Grad", selection: $belt) {
                        ForEach(BeltGrade.allCases, id: \.self) { belt in Text(belt.rawValue).tag(belt)}
                    }
                    TextField("Gewicht in kg", text: $weight)
                    DatePicker("Letzter Prüfungstermin", selection: $lastExamDate, displayedComponents: .date) // displayedComponents zeigt nur das Datum ohne Zeit an.
                    Picker("Kurs", selection: $course) {
                        ForEach(Course.allCases, id: \.self) { course in Text(course.rawValue).tag(course)}
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Button(action: saveStudent) { // Button der 'addstudent' Funktion aufruft
                    Text(studentToEdit == nil ? "Speichern" : "Änderungen Speichern")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity) // Breite des Knopfes auf die max verfügbare Breite
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle(studentToEdit == nil ? "Neuer Schüler" : "Schüler bearbeiten")
            .onAppear {
                if let student = studentToEdit {
                    name = student.name
                    firstName = student.firstName
                    birthDate = student.birthDate
                    belt = student.belt
                    weight = student.weight
                    lastExamDate = student.lastExamDate
                    course = student.course
                }
            }
        }
    }
    
    private func saveStudent() {
        if let student = studentToEdit {
            student.name = name
            student.firstName = firstName
            student.birthDate = birthDate
            student.belt = belt
            student.weight = weight
            student.lastExamDate = lastExamDate
            student.course = course
        } else {
            // Erstellt 'Student' Objekt mit den Eingabewerten
            let newStudent = Student(
                name: name,
                firstName: firstName,
                birthDate: birthDate,
                belt: belt,
                weight: weight,
                lastExamDate: lastExamDate,
                course: course)
            modelContext.insert(newStudent) // Fügt dem 'modelContext' hinzu
        }
        dismiss() // Ansicht schließen
    }
}
