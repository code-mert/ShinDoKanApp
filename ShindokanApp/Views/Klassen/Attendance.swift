//
//  Attendance.swift
//  ShindokanApp
//
//  Created by Mert Akdemir on 26.12.24.
//

import SwiftUI
import SwiftData

@Model
class Attendance {
    @Attribute var date: Date
    @Attribute var isPresent: Bool
    @Relationship var student: Student
    
    init(date: Date, isPresent: Bool, student: Student) {
        self.date = date
        self.isPresent = isPresent
        self.student = student
    }
}
