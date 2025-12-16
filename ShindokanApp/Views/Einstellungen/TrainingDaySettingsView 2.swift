import SwiftUI

struct TrainingDaySettingsView: View {
    // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    @AppStorage("trainingDay_2") private var monday = false
    @AppStorage("trainingDay_3") private var tuesday = false
    @AppStorage("trainingDay_4") private var wednesday = false
    @AppStorage("trainingDay_5") private var thursday = false
    @AppStorage("trainingDay_6") private var friday = false
    @AppStorage("trainingDay_7") private var saturday = false
    @AppStorage("trainingDay_1") private var sunday = false
    
    var body: some View {
        Form {
            Section(header: Text("Wähle deine Trainingstage")) {
                Toggle("Montag", isOn: $monday)
                Toggle("Dienstag", isOn: $tuesday)
                Toggle("Mittwoch", isOn: $wednesday)
                Toggle("Donnerstag", isOn: $thursday)
                Toggle("Freitag", isOn: $friday)
                Toggle("Samstag", isOn: $saturday)
                Toggle("Sonntag", isOn: $sunday)
            }
        }
        .navigationTitle("Trainingstage")
    }
}

#Preview {
    TrainingDaySettingsView()
}
