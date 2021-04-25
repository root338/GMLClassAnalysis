//
//  FileInfo.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/25.
//

import Foundation

struct FileInfo {
    typealias ContentRange = Range<String.Index>
    let content: String
    let noteRanges: [ContentRange]?
    
}
