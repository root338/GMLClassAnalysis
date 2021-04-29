//
//  ClassInfo.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/25.
//

import Foundation

enum ClassType {
    case interface
    case implementation
}

struct ClassInfo {
    let type: ClassType
    let className: String
    let extensionName: String?
    let superClassName: String?
}

struct OCClaseStruct {
    let info: ClassInfo?
    let propertys: [(info: PropertyStruct, range: FileTextRange)]?
    let methods: [(info: OCMethodStruct, range: FileTextRange)]?
//    let pragmaMarks: [FileTextRange]?
}

