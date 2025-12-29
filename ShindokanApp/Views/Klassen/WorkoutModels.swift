import Foundation
import SwiftData

@Model
class WorkoutPlan: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute var date: Date
    @Attribute var content: String
    @Attribute var createdAt: Date
    
    init(date: Date, content: String) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.createdAt = Date()
    }
}

enum PreferenceType: String, Codable, CaseIterable {
    case blacklist = "Blacklist"
    case favorite = "Favorit"
}

enum TrainingFocus: String, CaseIterable, Codable {
    case kumite = "Kumite"
    case kata = "Kata"
    case mixed = "Gemischt" // Fallback/Default
}

@Model
class DrillPreference: Identifiable {
    @Attribute(.unique) var id: UUID
    @Attribute var name: String
    @Attribute var details: String
    @Attribute var type: PreferenceType
    
    init(name: String, details: String = "", type: PreferenceType) {
        self.id = UUID()
        self.name = name
        self.details = details
        self.type = type
    }
}
