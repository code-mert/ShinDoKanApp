//
//  StudentDetailView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 05.06.24.
//

import SwiftUI

struct StudentDetailView: View {
    var student: Student

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Grid(horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    labelView("Alter:")
                    valueView("\(student.birthDate.age())")
                }
                GridRow {
                    labelView("Geburtsdatum:")
                    valueView(formatDate(student.birthDate))
                }
                GridRow {
                    labelView("Gürtelgraduierung:")
                    valueView(student.belt.rawValue)
                }
                GridRow {
                    labelView("Gewicht:")
                    valueView("\(student.weight) kg")
                }
                GridRow {
                    labelView("Letzter Prüfungstermin:")
                    if let lastExam = student.examDates.sorted(by: { $0.date > $1.date }).first {
                        NavigationLink(destination: ExamDatesListView(examDates: student.examDates, student: student)) {
                            valueView(formatDate(lastExam.date))
                        }
                    } else {
                        valueView("Keine Prüfung")
                    }
                }
                GridRow {
                    labelView("Kurs:")
                    valueView(student.course.rawValue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            NavigationLink(destination: AddStudentView(studentToEdit: student)) {
                Text("Bearbeiten")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("\(student.firstName) \(student.name)")
    }

    private func labelView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .frame(maxWidth: 200, alignment: .leading) // Feste Breite, um Textumbrüche zu vermeiden
    }

    private func valueView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20))
            .lineLimit(1) // Verhindert Umbrüche
            .truncationMode(.tail) // Kürzt zu lange Texte
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}


#Preview {
    let exampleStudent = Student(
        name: "Mert",
        firstName: "Akdemir",
        birthDate: Date(),
        belt: .kyu1,
        weight: "55",
        course: .advanced
    )
    StudentDetailView(student: exampleStudent)
}

struct ExamDatesListView: View {
    @Environment(\.modelContext) private var modelContext
    @State var newDate: Date = Date()
    @State var examDates: [ExamDate]
    var student: Student

    var body: some View {
        VStack {
            DatePicker("Neuer Prüfungstermin", selection: $newDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal)

            Button("Hinzufügen") {
                let newExam = ExamDate(date: newDate, student: student)
                examDates.append(newExam)
                student.examDates.append(newExam)
                modelContext.insert(newExam)
            }
            .padding(.bottom)

            List {
                ForEach(examDates.sorted(by: { $0.date > $1.date })) { exam in
                    Text(formatDate(exam.date))
                }
                .onDelete(perform: deleteExam)
            }
        }
        .navigationTitle("Prüfungstermine")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func deleteExam(at offsets: IndexSet) {
        for index in offsets {
            let exam = examDates.sorted(by: { $0.date > $1.date })[index]
            if let idx = student.examDates.firstIndex(where: { $0.id == exam.id }) {
                student.examDates.remove(at: idx)
            }
            modelContext.delete(exam)
        }
        examDates.remove(atOffsets: offsets)
    }
}
