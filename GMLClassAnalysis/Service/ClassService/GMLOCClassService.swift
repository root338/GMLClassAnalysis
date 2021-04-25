//
//  GMLOCClassService.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/24.
//

import Foundation

// 参考链接 https://m.aliyun.com/yunqi/ask/16378/
class GMLOCClassService: NSObject {
    lazy var findImportFileRE: NSRegularExpression = {
        let pattern = "#import[\\s]*\\\"[^\\\"]*\\\""
        return NSRegularExpression(pattern: pattern)
    }()
    lazy var findClassRE: NSRegularExpression = {
        let pattern = "(@interface|@implementation)((?!@end).)*@end"
        return try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    }()
    lazy var findClassNameRE: NSRegularExpression = {
        let pattern = "(@interface|@implementation)[\\sa-zA-Z0-9_]+(\\([\\sa-zA-Z0-9]*\\)|)"
        return NSRegularExpression(pattern: pattern)
    }()
    
    lazy var findPropertyRE: NSRegularExpression = {
        let pattern = "(@property|@synthesize|@dynamic)[^;]*;"
        return NSRegularExpression(pattern: pattern)
    }()
    lazy var findMethodRE: NSRegularExpression = {
        let pattern = "[^\n\\S]*(-|\\+)[\\s]*\\(([^\\(\\)\\{\\}]|(\\([^\\(\\)\\{\\}]*\\)))*\\)[^\\{\\};/@]+[\\s]*\\{([^\\{\\}]|(\\{[^\\{\\}]*\\}))*\\}"
        return NSRegularExpression(pattern: pattern)
    }()
    lazy var findMethodNameRE: NSRegularExpression = {
        let pattern = "[^\n\\S]*(-|\\+)[\\s]*\\(([^\\(\\)\\{\\}]|(\\([^\\(\\)\\{\\}]*\\)))*\\)[^\\{\\};/@]+"
        return NSRegularExpression(pattern: pattern)
    }()
    lazy var findNoteRE: NSRegularExpression = {
        let pattern = "(//[^\\\n]*)|(/\\*((?!\\*/).)*\\*/)"
        return try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    }()
    lazy var findMethodBodyRE: NSRegularExpression = {
        let pattern = "\\{([^\\{\\}]|(\\{[^\\{\\}]*\\}))*\\}"
        return NSRegularExpression(pattern: pattern)
    }()
}

extension GMLOCClassService {
    typealias CodeResult = (codes: [String], ranges: [Range<String.Index>])
    
    /// 获取全部有意义的代码
    /// - Returns: code: 表示有意义的代码, ranges 表示注释
    func fullCode(content: String) -> (fullCode: String, noteRanges: [Range<String.Index>]) {
        var noteRanges = [Range<String.Index>]()
        var previousRange: Range<String.Index>? = nil
        var fullCodeContent = String()
        findNoteRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            noteRanges.append(range)
            let codeRange = (previousRange?.upperBound ?? content.startIndex) ..< range.lowerBound
            fullCodeContent.append(String(content[codeRange]))
            previousRange = range
        }
        if let lastRange = previousRange {
            fullCodeContent.append(String(content[lastRange.upperBound ..< content.endIndex]))
        }
        return (fullCodeContent, noteRanges)
    }
}
extension GMLOCClassService {
    func classCode(content: String) -> CodeResult {
        var classCodes = [String]()
        var classCodeRanges = [Range<String.Index>]()
        findClassRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            classCodes.append(String(content[range]))
            classCodeRanges.append(range)
        }
        return (classCodes, classCodeRanges)
    }
    func classCodeInfo(content: String) -> (codeInfo: ClassCodeBlockInfo, range: Range<String.Index>)? {
        var codeInfo: ClassCodeBlockInfo?
        var mRange: Range<String.Index>?
        
        findClassNameRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            mRange = range
            codeInfo = classInfo(content: String(content[range]))
        }
        if codeInfo == nil { return nil }
        return (codeInfo!, mRange!)
    }
}
fileprivate extension GMLOCClassService {
    func classInfo(content: String) -> ClassCodeBlockInfo? {
        let arr = content.split { (char) -> Bool in
            return char == " " || char == "\n"
        }
        let type: ClassType = arr[0] == "@interface" ? .interface : .implementation
        let className = String(arr[1])
        var extensionName: String?
        var mark = false
        for i in 2 ..< arr.count {
            let text = arr[i]
            if mark {
                extensionName = String(text == ")" ? "" : text)
                break
            }
            if text == "(" {
                mark = true
            }
        }
        return ClassCodeBlockInfo(type: type, className: className, extensionName: extensionName)
    }
}
