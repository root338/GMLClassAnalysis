//
//  MethodInfo.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/27.
//

import Foundation

enum MethodType {
    case `class`
    case instance
}

struct OCMethodStruct {
    let name: String
    let selector: Selector
    let type: MethodType
}
