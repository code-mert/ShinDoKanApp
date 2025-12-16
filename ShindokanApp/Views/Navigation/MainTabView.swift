import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "house.fill")
                }
            
            StudentListView()
                .tabItem {
                    Label("Schüler", systemImage: "person.3.fill")
                }
            
            AttendanceView()
                .tabItem {
                    Label("Anwesenheit", systemImage: "checkmark.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
}
