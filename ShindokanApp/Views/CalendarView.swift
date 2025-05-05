//
//  CalendarView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [CalendarEntry]
    
    @State private var showAddEntry = false
    @State private var selectedEntry: CalendarEntry? = nil
    @State private var showEntryDetails = false
    
    var body: some View {
        VStack {
            List {
                ForEach(entries.sorted(by: { $0.date < $1.date })) { entry in
                    Text("\(entry.date.formatted(date: .abbreviated, time: .omitted)) - \(entry.title)")
                        .onTapGesture {
                            selectedEntry = entry
                            showEntryDetails = true
                        }
                }
            }
        }
        .sheet(isPresented: $showEntryDetails) {
            let selectedDateEntries = entries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedEntry?.date ?? Date()) }
            EntryDetailView(entries: selectedDateEntries)
        }
    }
    
    struct EntryDetailView: View {
        var entries: [CalendarEntry]
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) var context
        
        @State private var entryBeingEdited: CalendarEntry? = nil
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Datum: \(entry.date.formatted(date: .abbreviated, time: .shortened))")
                            Text("Titel: \(entry.title)")
                            if let note = entry.note {
                                Text("Notiz: \(note)")
                            }

                            HStack {
                                Button("Bearbeiten") {
                                    entryBeingEdited = entry
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Löschen", role: .destructive) {
                                    context.delete(entry)
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .sheet(item: $entryBeingEdited) { entry in
                EditEntryView(entry: entry)
            }
        }
    }
    
}

struct AddCalendarEntryView: View {
    @State private var selectedDate: Date = .now
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var title = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Datum")) {
                    DatePicker("Datum", selection: $selectedDate, displayedComponents: [.date])
                }
                
                Section(header: Text("Titel")) {
                    TextField("Eintragstitel", text: $title)
                }
                
                Section(header: Text("Notiz")) {
                    TextField("Zusätzliche Notiz", text: $note)
                }
            }
            .navigationTitle("Neuer Eintrag")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let newEntry = CalendarEntry(date: selectedDate, title: title, note: note.isEmpty ? nil : note)
                        context.insert(newEntry)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditEntryView: View {
    var entry: CalendarEntry
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: EditEntryViewModel

    init(entry: CalendarEntry) {
        self.entry = entry
        _viewModel = StateObject(wrappedValue: EditEntryViewModel(entry: entry))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Datum")) {
                    DatePicker("Datum", selection: $viewModel.date, displayedComponents: [.date])
                }

                Section(header: Text("Titel")) {
                    TextField("Eintragstitel", text: $viewModel.title)
                }

                Section(header: Text("Notiz")) {
                    TextField("Zusätzliche Notiz", text: $viewModel.note)
                }
            }
            .navigationTitle("Eintrag bearbeiten")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        viewModel.applyChanges(to: entry)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Binding {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}

@Model
class CalendarEntry: Identifiable {
    var id: UUID
    var date: Date
    var title: String
    var note: String?

    init(date: Date, title: String, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.note = note
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        var current = interval.start

        while current < interval.end {
            if let next = self.nextDate(after: current, matching: components, matchingPolicy: .nextTime) {
                if next < interval.end {
                    dates.append(next)
                    current = next
                } else {
                    break
                }
            } else {
                break
            }
        }

        return dates
    }
}

class EditEntryViewModel: ObservableObject {
    @Published var date: Date
    @Published var title: String
    @Published var note: String

    init(entry: CalendarEntry) {
        self.date = entry.date
        self.title = entry.title
        self.note = entry.note ?? ""
    }

    func applyChanges(to entry: CalendarEntry) {
        entry.date = date
        entry.title = title
        entry.note = note.isEmpty ? nil : note
    }
}
