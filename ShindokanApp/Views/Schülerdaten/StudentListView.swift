//
//  StudentListView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.name) private var students: [Student]
    @State private var isPresentingAddStudentView = false
    
    @State private var showAlert = false
    @State private var filterText = ""
    @State private var selectedCourse: Course? = nil
    @State private var studentToArchive: Student?
    
    var filteredStudentList: [Student] {
        students.filter {
            !$0.isArchived && // Nur aktive Schüler anzeigen
            (filterText.isEmpty ||
             "\($0.firstName) \($0.name)".localizedCaseInsensitiveContains(filterText) ||
             String($0.birthDate.age()).contains(filterText))
            && (selectedCourse == nil || $0.course == selectedCourse)
        }
    }

    var body: some View {
        NavigationStack {
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
                    Text("Anzahl Schüler: \(filteredStudentList.count)")
                }
                List {
                    ForEach(filteredStudentList) { student in
                        NavigationLink(destination: StudentDetailView(student: student)) {
                            VStack(alignment: .leading) {
                                Text("\(student.firstName) \(student.name)")
                                    .font(.headline)
                                Text("Alter: \(student.birthDate.age())")
                                Text("Kurs: \(String(describing: student.course.rawValue))")
                            }
                        }
                    }
                    .onDelete(perform: prepareToArchiveStudent)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        NavigationLink(destination: ArchivedStudentsView()) {
                            Image(systemName: "archivebox")
                        }
                        
                        Button(action: {
                            isPresentingAddStudentView = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddStudentView) {
                AddStudentView()
                    .environment(\.modelContext, modelContext)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Archivieren"),
                    message: Text("Möchten Sie \(studentToArchive?.firstName ?? "")\(studentToArchive?.name ?? "diesen Schüler") wirklich archivieren?"),
                    primaryButton: .destructive(Text("Archivieren")) {
                        if let student = studentToArchive {
                            archiveStudent(student: student)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationTitle("Schüler")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func prepareToArchiveStudent(at offsets: IndexSet) {
        if let index = offsets.first {
            studentToArchive = filteredStudentList[index]
            showAlert = true
        }
    }
    
    private func archiveStudent(student: Student) {
        student.isArchived = true
        do {
            try modelContext.save()
        } catch {
            print("Error archiving student: \(error)")
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
