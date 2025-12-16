import SwiftUI
import SwiftData

struct AttendanceView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Bitte Kurs auswählen")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                
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
                
                Spacer()
            }
            .navigationTitle("Anwesenheit")
        }
    }
}
