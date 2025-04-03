//
//  CourseSelectionView.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 26.12.24.
//

import SwiftUI
import SwiftData

struct CourseSelectionView: View {
    var body: some View {
        VStack {
            NavigationLink(destination: AttendanceListView(courseType: .beginner)) {
                Text("Anfänger Kurs")
                    .font(.title)
                    .frame(width: 300, height: 50)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            .padding()
            
            NavigationLink(destination: AttendanceListView(courseType: .advanced)) {
                Text("Fortgeschrittenen Kurs")
                    .font(.title)
                    .frame(width: 300, height: 50)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            .padding()
            Spacer() // Sorgt dafür dass die Boxen oberhalb platziert sind. 
        }
        .navigationTitle("Kursauswahl")
    }
}
