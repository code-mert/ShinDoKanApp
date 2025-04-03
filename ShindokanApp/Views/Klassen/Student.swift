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
    case kyu9 = "9. Kyu"
    case kyu89 = "9./8. Kyu"
    case kyu8 = "8. Kyu"
    case kyu78 = "8./7. Kyu"
    case kyu7 = "7. Kyu"
    case kyu67 = "7./6. Kyu"
    case kyu6 = "6. Kyu"
    case kyu56 = "6./5. Kyu"
    case kyu5 = "5. Kyu"
    case kyu45 = "5./4. Kyu"
    case kyu4 = "4. Kyu"
    case kyu3 = "3. Kyu"
    case kyu2 = "2. Kyu"
    case kyu1 = "1. Kyu"
}
