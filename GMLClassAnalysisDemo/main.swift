//
//  main.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/23.
//

import Foundation

let filePath = "/Users/ml/yuemei_mainAPP/QuickAskCommunity/QuickAskCommunity/Classes/Module/Search/Controller/SearchViewController.m"
let content = try! NSString(contentsOfFile: filePath, encoding: String.Encoding.utf8.rawValue) as String
let classService = GMLOCClassService()
let fullCodeResult = classService.fullCode(content: content)
//print(fullCodeResult.fullCode)
let classCodeResult = classService.classCode(content: fullCodeResult.fullCode)
for classCode in classCodeResult.codes {
    print(classService.classCodeInfo(content: classCode)?.codeInfo)
}
