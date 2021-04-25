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
}

struct ClassCodeBlockInfo {
    let type: ClassType
    let className: String
    let extensionName: String?
}
