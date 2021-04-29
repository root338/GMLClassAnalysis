//
//  OCFileAnalysisService.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/24.
//

import Foundation

// 参考链接 https://m.aliyun.com/yunqi/ask/16378/
class OCFileAnalysisService: NSObject {
    //MARK:- Find File Info
    // 查找导入头文件
    lazy var findImportFileRE: NSRegularExpression = {
        let pattern = "#import[\\s]*\\\"[^\\\"]*\\\""
        return try! NSRegularExpression(pattern: pattern)
    }()
    // 查找类
    lazy var findClassRE: NSRegularExpression = {
        let pattern = "(@interface|@implementation)((?!@end).)*@end"
        return try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    }()
    
    // 查找属性
    lazy var findPropertyRE: NSRegularExpression = {
        let pattern = "(@property|@synthesize|@dynamic)[\\s]+[^;]*;"
        return try! NSRegularExpression(pattern: pattern)
    }()
    // 查找方法
    lazy var findMethodRE: NSRegularExpression = {
        let pattern = "[^\n\\S]*(-|\\+)[\\s]*\\(([^\\(\\)\\{\\}]|(\\([^\\(\\)\\{\\}]*\\)))*\\)[^\\{\\};/@]+[\\s]*\\{([^\\{\\}]|(\\{[^\\{\\}]*\\}))*\\}"
        return try! NSRegularExpression(pattern: pattern)
    }()
    // 查找方法名
    lazy var findMethodNameRE: NSRegularExpression = {
        let pattern = "[^\n\\S]*(-|\\+)[\\s]*\\(([^\\(\\)\\{\\}]|(\\([^\\(\\)\\{\\}]*\\)))*\\)[^\\{\\};/@]+"
        return try! NSRegularExpression(pattern: pattern)
    }()
    // 查找注释
    lazy var findNoteRE: NSRegularExpression = {
        let pattern = "(//[^\\\n]*)|(/\\*((?!\\*/).)*\\*/)"
        return try! NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
    }()
    // 查找被大括号({})包围的代码块
    lazy var findSurroundedByBracesCodeRE: NSRegularExpression = {
        let pattern = "\\{([^\\{\\}]|(\\{[^\\{\\}]*\\}))*\\}"
        return try! NSRegularExpression(pattern: pattern)
    }()
    
    //MARK:- Class Info
    // 查找类/扩展的头部信息
    lazy var findClassInfoRE: NSRegularExpression = {
        let classChar = "[a-zA-Z0-9_]"
        let pattern = "(@interface|@implementation)[\\s]+\(classChar)+[\\s]*(\\([\\s]*\(classChar)*[\\s]*\\)|[\\s*]:[\\s]*\(classChar)+|)"
        return try! NSRegularExpression(pattern: pattern)
    }()
    private lazy var findClassTypeRE: NSRegularExpression = {
        let pattern = "(@interface|@implementation)"
        return try! NSRegularExpression(pattern: pattern)
    }()
    private lazy var findClassExtensionRE: NSRegularExpression = {
        let pattern = "\\(\\s*[a-zA-Z0-9_]*\\s*\\)"
        return try! NSRegularExpression(pattern: pattern)
    }()
    lazy var findClassSuperRE: NSRegularExpression = {
        let pattern = ":\\s*\\([a-zA-Z0-9_]*\\s*\\)"
        return try! NSRegularExpression(pattern: pattern)
    }()
}

//MARK:- File Analysis
extension OCFileAnalysisService {
    /// 获取文件信息
    /// - Parameters:
    ///   - content: 文件内容
    ///   - configuration: 解析文本的详细配置，默认为 nil
    func fileInfo(content: String, configuration: FileAnalysisConfiguration? = nil) -> (info: ClassFileStruct, fullCode: String) {
        var annotatedRanges = [FileTextRange]()
        var codeRanges = [FileTextRange]()
        var previousRange: FileTextRange? = nil
        var classStructs: [ClassFileStruct.ClassInfo]?
        
        var fullCodeContent = String()
        let isGetFullCode = configuration?.isGetFullCode ?? false
        
        func appendCodeRange(annotatedRange: FileTextRange?) {
            let codeRange = (previousRange?.upperBound ?? content.startIndex) ..< (annotatedRange?.lowerBound ?? content.endIndex)
            codeRanges.append(codeRange)
            if isGetFullCode { fullCodeContent.append(String(content[codeRange])) }
            previousRange = annotatedRange
        }
        findNoteRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            annotatedRanges.append(range)
            appendCodeRange(annotatedRange: range)
        }
        appendCodeRange(annotatedRange: nil)
        if isGetFullCode, let config = configuration {
            classStructs = classStruct(
                content: fullCodeContent,
                configuration: config.class
            )
        }
        return (
            ClassFileStruct(
                annotatedRanges: annotatedRanges,
                codeRanges: codeRanges,
                classStructs: classStructs ?? []),
            fullCodeContent
        )
    }
}

//MARK:- Class Analysis
extension OCFileAnalysisService {
    func classStruct(content: String, configuration: ClassAnalysisConfiguration? = nil) -> [ClassFileStruct.ClassInfo] {
        var classInfos = [ClassFileStruct.ClassInfo]()
        
        findClassRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            var classStruct: OCClaseStruct?
            if let config = configuration {
                let classContent = String(content[range])
                classStruct = OCClaseStruct(
                    info: config.isGetClassInfo ? self.classInfo(content: classContent) : nil,
                    propertys: nil,
                    methods: nil
                )
            }
            classInfos.append((classStruct, range))
        }
        return classInfos
    }
}

extension OCFileAnalysisService {
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
extension OCFileAnalysisService {
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
//    func classCodeInfo(content: String) -> (codeInfo: ClassCodeBlockInfo, range: Range<String.Index>)? {
//        var codeInfo: ClassCodeBlockInfo?
//        var mRange: Range<String.Index>?
//
//        findClassNameRE.enumerateMatches(in: content, options: .reportCompletion, range: content.rangeAll) { (textCheckingResult, _, _) in
//            guard let result = textCheckingResult else { return }
//            guard let range = Range(result.range, in: content) else { return }
//            mRange = range
//            codeInfo = classInfo(content: String(content[range]))
//        }
//        if codeInfo == nil { return nil }
//        return (codeInfo!, mRange!)
//    }
}

//MARK:- Private Analysis
fileprivate extension OCFileAnalysisService {
//    func classInfo(content: String) -> ClassCodeBlockInfo? {
//        let arr = content.split { (char) -> Bool in
//            return char == " " || char == "\n"
//        }
//        let type: ClassType = arr[0] == "@interface" ? .interface : .implementation
//        let className = String(arr[1])
//        var extensionName: String?
//        var mark = false
//        for i in 2 ..< arr.count {
//            let text = arr[i]
//            if mark {
//                extensionName = String(text == ")" ? "" : text)
//                break
//            }
//            if text == "(" {
//                mark = true
//            }
//        }
//        return ClassCodeBlockInfo(type: type, className: className, extensionName: extensionName)
//    }
    
    func classInfo(content: String) -> ClassInfo? {
        guard let classInfo = findClassInfoRE.firstMatch(in: content) else { return nil }
        guard let (classMarkStr, range) = findClassTypeRE.firstMatch(in: classInfo.str) else { return nil }
        var classType: ClassType!
        var superClassInfo: (str: String, range: FileTextRange)?
        var classNameEndIndex: String.Index?
        switch classMarkStr {
        case "@interface":
            classType = .interface
            superClassInfo = findClassSuperRE.firstMatch(in: classInfo.str)
            superClassInfo?.str.removeFirst()
            if let superClassName = superClassInfo?.str.deleteBlankCharacter {
                superClassInfo?.str = superClassName
                classNameEndIndex = superClassInfo?.range.lowerBound
            }
        case "@implementation":
            classType = .implementation
        default:
            return nil
        }
        
        var extensionInfo = findClassExtensionRE.firstMatch(in: classInfo.str)
        extensionInfo?.str.removeFirst()
        extensionInfo?.str.removeLast()
        if let extensionName = extensionInfo?.str.deleteBlankCharacter {
            extensionInfo?.str = extensionName
        }
        let classNameLastIndex = classNameEndIndex ?? (extensionInfo?.range.lowerBound ?? classInfo.str.endIndex)
        return ClassInfo(
            type: classType,
            className: String(classInfo.str[range.upperBound ..< classNameLastIndex]).deleteBlankCharacter,
            extensionName: extensionInfo?.str,
            superClassName: superClassInfo?.str
        )
    }
}
