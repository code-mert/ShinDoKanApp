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
                    valueView(formatDate(student.lastExamDate))
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
        lastExamDate: Date(),
        course: .advanced
    )
    StudentDetailView(student: exampleStudent)
}
