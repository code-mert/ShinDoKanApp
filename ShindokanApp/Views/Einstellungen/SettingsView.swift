import SwiftUI
import SwiftData


struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: TrainingDaySettingsView()) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                            Text("Trainingstage")
                        }
                    }
                    
                    NavigationLink(destination: AISettingsView()) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("KI Training")
                        }
                    }
                } header: {
                    Text("Allgemein")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}

struct AISettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("openai_api_key") private var apiKey = ""
    @AppStorage("workout_duration") private var duration = 60
    
    @Query(sort: \DrillPreference.name) var allPreferences: [DrillPreference]
    
    var favorites: [DrillPreference] {
        allPreferences.filter { $0.type == .favorite }
    }
    
    var blacklist: [DrillPreference] {
        allPreferences.filter { $0.type == .blacklist }
    }
    
    @State private var newDrillName = ""
    @State private var newDrillDescription = ""
    @State private var selectedPreferenceType: PreferenceType = .favorite
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Konfiguration")) {
                SecureField("API Key", text: $apiKey)
                Picker("Dauer (Minuten)", selection: $duration) {
                    Text("45 Min").tag(45)
                    Text("60 Min").tag(60)
                    Text("90 Min").tag(90)
                }
            }
            
            Section(header: Text("Neuen Eintrag hinzufügen")) {
                VStack(spacing: 12) {
                    TextField("Übung (z.B. Burpees)", text: $newDrillName)
                    TextField("Beschreibung (optional, z.B. nur Aufwärmen)", text: $newDrillDescription)
                        .font(.caption)
                    
                    HStack {
                        Picker("Typ", selection: $selectedPreferenceType) {
                            ForEach(PreferenceType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: addPreference) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                        .disabled(newDrillName.isEmpty)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Favoriten (Bevorzugen)")) {
                if favorites.isEmpty {
                    Text("Keine Favoriten").foregroundColor(.secondary)
                } else {
                    ForEach(favorites) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            if !item.details.isEmpty {
                                Text(item.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in deleteItems(at: indexSet, from: favorites) }
                }
            }
            
            Section(header: Text("Blacklist (Vermeiden)")) {
                if blacklist.isEmpty {
                    Text("Keine Einträge").foregroundColor(.secondary)
                } else {
                    ForEach(blacklist) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            if !item.details.isEmpty {
                                Text(item.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in deleteItems(at: indexSet, from: blacklist) }
                }
            }
        }
        .navigationTitle("KI Einstellungen")
    }
    
    private func addPreference() {
        let newItem = DrillPreference(name: newDrillName, details: newDrillDescription, type: selectedPreferenceType)
        modelContext.insert(newItem)
        newDrillName = ""
        newDrillDescription = ""
    }
    
    private func deleteItems(at offsets: IndexSet, from list: [DrillPreference]) {
        for index in offsets {
            modelContext.delete(list[index])
        }
    }
}
