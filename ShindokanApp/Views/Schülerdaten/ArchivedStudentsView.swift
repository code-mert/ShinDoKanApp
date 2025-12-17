import SwiftUI
import SwiftData

struct ArchivedStudentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Student> { $0.isArchived }, sort: \Student.name) private var archivedStudents: [Student]
    
    @State private var showingDeleteAlert = false
    @State private var studentToDelete: Student?

    var body: some View {
        List {
            if archivedStudents.isEmpty {
                Text("Keine archivierten Schüler")
                    .foregroundColor(.secondary)
            } else {
                ForEach(archivedStudents) { student in
                    VStack(alignment: .leading) {
                        Text("\(student.firstName) \(student.name)")
                            .font(.headline)
                            .strikethrough() // Visual indicator
                        Text("Kurs: \(student.course.rawValue)")
                            .font(.caption)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            restoreStudent(student)
                        } label: {
                            Label("Wiederherstellen", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            studentToDelete = student
                            showingDeleteAlert = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Archiv")
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Endgültig löschen"),
                message: Text("Möchten Sie \(studentToDelete?.firstName ?? "") \(studentToDelete?.name ?? "") unwiderruflich löschen?"),
                primaryButton: .destructive(Text("Löschen")) {
                    if let student = studentToDelete {
                        deletePermanently(student)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func restoreStudent(_ student: Student) {
        student.isArchived = false
        try? modelContext.save()
    }
    
    private func deletePermanently(_ student: Student) {
        modelContext.delete(student)
        try? modelContext.save()
    }
}
