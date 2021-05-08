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
struct ClassInfoRange {
    
    let type: GMLTextInfoRange
    let name: GMLTextInfoRange?
    let extensionName: GMLTextInfoRange?
    let superClassName: GMLTextInfoRange?
}

struct OCClaseStruct {
    typealias PropertyTextInfo = (info: PropertyInfo?, range: FileTextRange)
//    let info: ClassDetailInfo?
    let info: ClassInfo?
    let propertys: [PropertyTextInfo]?
    let methods: [(info: OCMethodStruct?, range: FileTextRange)]?
//    let pragmaMarks: [FileTextRange]?
}

