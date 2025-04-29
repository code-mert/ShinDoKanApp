//
//  Student.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 28.05.24.
//

import Foundation // Foundation Framework
import SwiftData

@Model // Attribut, das angibt, dass diese Klasse ein Datenmodell ist, das von SwiftData verwaltet wird
class Student: Identifiable { // Identifiable erfordert, dass die Klasse eine eindeutige id-Eigenschaft hat
    @Attribute(.unique) var id: UUID // Eine Eigenschaft, die eine eindeutige ID für jedes 'Student'-Objekt speichert. Der Typ ist UUID.
    @Attribute var name: String
    @Attribute var firstName: String
    @Attribute var birthDate: Date = Date()
    @Attribute var beltRaw: BeltGrade?
    @Attribute var weight: String
    @Attribute var lastExamDate: Date
    @Attribute var course: Course
    @Relationship var attendances: [Attendance] = []
    
    // Falls beltGrade = 0, dann Standardwert Kyu9 verwendet
    var belt: BeltGrade {
        get { beltRaw ?? .kyu9}
        set { beltRaw = newValue}}

    init(name: String, firstName: String, birthDate: Date, belt: BeltGrade?, weight: String, lastExamDate: Date, course: Course = .beginner) { // Initializer, der aufgerufen wird, wenn ein neues 'Student'-Objekt erstellt wird.
        self.id = UUID()
        self.name = name
        self.firstName = firstName
        self.birthDate = birthDate
        self.beltRaw = belt
        self.weight = weight
        self.lastExamDate = lastExamDate
        self.course = course
    }
}

enum Course: String, Codable, CaseIterable {
    case beginner = "Anfänger"
    case advanced = "Fortgeschritten"
}


enum BeltGrade: String, Codable, CaseIterable {
    case kyu9 = "9. Kyu - weiß"
    case kyu89 = "9./8. Kyu - weiß/gelb"
    case kyu8 = "8. Kyu - gelb"
    case kyu78 = "8./7. Kyu - gelb/orange"
    case kyu7 = "7. Kyu - orange"
    case kyu67 = "7./6. Kyu - orange-grün"
    case kyu6 = "6. Kyu - grün"
    case kyu56 = "6./5. Kyu - grün/blau"
    case kyu5 = "5. Kyu - blau"
    case kyu4 = "4. Kyu - blau 2"
    case kyu3 = "3. Kyu - braun 1"
    case kyu2 = "2. Kyu - braun 2"
    case kyu1 = "1. Kyu - braun 3"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let grade = BeltGrade(rawValue: rawValue) {
            self = grade
        } else {
            // Versuche alternative Zuordnungen
            switch rawValue {
            case "9. Kyu":
                self = .kyu9
            case "9./8. Kyu":
                self = .kyu89
            case "8. Kyu":
                self = .kyu8
            case "8./7. Kyu":
                self = .kyu78
            case "7. Kyu":
                self = .kyu7
            case "7./6. Kyu":
                self = .kyu67
            case "6. Kyu":
                self = .kyu6
            case "6./5. Kyu":
                self = .kyu56
            case "5. Kyu":
                self = .kyu5
            case "4. Kyu":
                self = .kyu4
            case "3. Kyu":
                self = .kyu3
            case "2. Kyu":
                self = .kyu2
            case "1. Kyu":
                self = .kyu1
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Ungültiger Gürtelgrad: \(rawValue)")
            }
        }
    }
}
