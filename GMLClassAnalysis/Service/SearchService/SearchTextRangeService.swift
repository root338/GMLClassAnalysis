//
//  SearchTextRangeService.swift
//  GMLXcodeTool
//
//  Created by GML on 2021/5/1.
//

import Foundation

class SearchTextRangeService: NSObject {
    
}

//MARK:- Class Range Search
extension SearchTextRangeService {
    func classEndIndex(content: String, fileStruct: ClassFileStruct, isAnalysis: (OCClaseStruct?, FileTextRange) -> Bool = { (_, _) in true }, result: (OCClaseStruct?, String.Index) -> Bool) {
        if fileStruct.classStructs.isEmpty { return }
        for classInfo in fileStruct.classStructs {
            if !isAnalysis(classInfo.info, classInfo.range) { continue }
            var previousCodeEndIndex = content.startIndex
            var distance = -4
            for codeRange in fileStruct.codeRanges {
                distance += content.distance(from: previousCodeEndIndex, to: codeRange.lowerBound)
                let index = content.index(
                    classInfo.range.upperBound,
                    offsetBy: distance
                )
                if codeRange.contains(index) {
                    let isNext = result(classInfo.info, index)
                    if isNext {
                        break
                    }else {
                        return
                    }
                }
                previousCodeEndIndex = codeRange.upperBound
            }
        }
    }
    
}
