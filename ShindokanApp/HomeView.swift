//
//  Homeview.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import SwiftUI
import SwiftData

struct HomeView: View { // Erstellung neuer Ansicht "HomeView"
    // @Environment(\.modelContext) var modelContext
    var body: some View {
        NavigationStack { // Ermöglicht Wechsel zwischen verschiedenen Ansichten
            VStack { // Ordnet die Inhalte vertikal an (oben nach unten)
                NavigationLink(destination: StudentListView()) { // Knopf der beim Klicken auf StudentListView wechselt
                    Text("Schüler Daten") // Text auf Knopf
                        .font(.title) // Setzt Schriftgröße auf Titelgröße
                        .frame(width: 300, height: 50)
                        .padding() // Fügt Abstand um den Text hinzu
                        .background(Color.orange) // Hintergrund des Knopfes
                        .foregroundColor(.black) // Textfarbe
                        .cornerRadius(10) // Macht die Ecken des Knopfes abgerundet
                }
                .padding() // Abstand um den Knopf
                
                NavigationLink(destination: CourseSelectionView()) {
                    Text("Anwesenheitsliste")
                        .font(.title)
                        .frame(width: 300, height: 50)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .padding()

                Spacer() // Fügt flexiblen Raum hinzu, der den restlichen Platz ausfüllt und andere Elemente nach oben drückt.

                CalendarView() // Zeigt Ansicht für den Kalender an
                    .frame(height: 300) // Setzt Höhe des Kalenders auf 300 Punkte
                    .padding()
            }
            .navigationTitle("Shindokan App") // Titel der Navigationsleiste
        }
    }
}

#Preview {
    HomeView()
}
