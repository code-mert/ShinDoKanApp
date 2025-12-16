import SwiftUI

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
