//
//  FileInfo.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/25.
//

import Foundation

struct ClassFileStruct {
    typealias ClassInfo = (info: OCClaseStruct?, range: FileTextRange)
    
    // 注释范围
    let annotatedRanges: [FileTextRange]
    // 代码范围
    let codeRanges: [FileTextRange]
    // 包含的类结构集合
    let classStructs: [ClassInfo]
}
