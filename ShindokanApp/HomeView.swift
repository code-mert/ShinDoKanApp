//
//  Homeview.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct HomeView: View { // Erstellung neuer Ansicht "HomeView"
    @Environment(\.modelContext) var modelContext
    @State private var showAddEntry = false
    var body: some View {
        NavigationStack { // Ermöglicht Wechsel zwischen verschiedenen Ansichten
            VStack { // Ordnet die Inhalte vertikal an (oben nach unten)
                HStack {
                    Text("Zukünftige Ereignisse")
                        .font(.title)
                        .bold()
                    Spacer()
                    Button(action: {
                        showAddEntry = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
                
                CalendarView()
                
                Spacer()
                
                HStack {
                    NavigationLink(destination: StudentListView()) {
                        Image(systemName: "person.3.fill")
                            .font(.title)
                            .frame(width: 140, height: 50)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }

                    NavigationLink(destination: CourseSelectionView()) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.title)
                            .frame(width: 140, height: 50)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showAddEntry) {
                AddCalendarEntryView()
            }
            .onAppear {
                #if DEBUG
                createDemoStudentsIfNeeded(modelContext: modelContext)
                #endif
            }
            .navigationTitle("Shindokan App") // Titel der Navigationsleiste
        }
    }
}

#Preview {
    HomeView()
}
