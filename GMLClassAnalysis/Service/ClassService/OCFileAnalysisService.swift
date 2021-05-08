//
//  OCFileAnalysisService.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/24.
//

import Foundation

// 正则表达式参考链接 https://m.aliyun.com/yunqi/ask/16378/

/// OC 文件解析服务
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
    lazy var findParadigmRE: NSRegularExpression = {
        let pattern = "<((?!>).)*>"
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
    //MARK:- Property Info
    lazy var findPropertyTypeRE: NSRegularExpression = {
        let pattern = "(@property|@synthesize|@dynamic)"
        return try! NSRegularExpression(pattern: pattern)
    }()
    lazy var findPropertyUnitRE: NSRegularExpression = {
        let pattern = "\\([\\sa-zA-Z0-9,_]+\\)"
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
                    propertys: config.property != nil ? self.propertyStruct(content: classContent, configuration: config.property) : nil,
                    methods: nil
                )
            }
            classInfos.append((classStruct, range))
        }
        return classInfos
    }
}
//MARK:- Property Analysis
extension OCFileAnalysisService {
    /// 解析指定文本的属性
    func propertyStruct(content: String, configuration: PropertyAnalysisConfiguration? = nil) -> [(info: PropertyInfo?, range: FileTextRange)] {
        var propertyInfos = [(info: PropertyInfo?, range: FileTextRange)]()
        findPropertyRE.enumerateMatches(in: content, options: [], range: content.rangeAll) { (textCheckingResult, _, _) in
            guard let result = textCheckingResult else { return }
            guard let range = Range(result.range, in: content) else { return }
            var propertys: [PropertyInfo]?
            if configuration != nil {
                let text = String(content[range])
                propertys = propertyInfo(content: text)
            }
            if let list = propertys, list.count > 1 {
                assert(false, "\(list) 为数组的情况下没有处理")
            }else {
                propertyInfos.append((propertys?.first, range))
            }
        }
        return propertyInfos
    }
    
    /// 合并同一个类下的同属性内容
    /// - Returns: 返回一个字典 [类名： [属性名：属性内容]]
    func mergeProperty<T>(list: [T], analysisClass: (T) -> OCClaseStruct?) -> [String: [PropertyInfo]] {
        var dict = [String: [String: PropertyInfo]]()
        for item in list {
            guard let classStruct = analysisClass(item) else { continue }
            let className = classStruct.info?.className ?? ""
            guard let propertys = classStruct.propertys else { continue }
            var propertyDict = dict[className] ?? [String: PropertyInfo]()
            
            for propertyInfo in propertys {
                guard let info = propertyInfo.info else { continue }
                let propertyName = info.name
                propertyDict[propertyName] = propertyDict[propertyName]?.merge(info: info) ?? info
            }
            dict[className] = propertyDict
        }
        var resultDict = [String: [PropertyInfo]]()
        for (key, value) in dict {
            resultDict[key] = Array(value.values)
        }
        return resultDict
    }
//    func fullPropertyList(fileInfo: ClassFileStruct) {
//        
//        for obj in fileInfo.classStructs {
//            guard let classInfo = obj.info else { continue }
//            guard let propertyInfoList = classInfo.propertys, !propertyInfoList.isEmpty else { continue }
//            for info in propertyInfoList {
//                guard let propertyInfo = info.info else { continue }
//                
//            }
//        }
//    }
}

//MARK:- Private Analysis
fileprivate extension OCFileAnalysisService {
    
    /// 解析类的基础信息
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
    /// 属性解析
    /// 不支持 block 的解析
    func propertyInfo(content: String) -> [PropertyInfo]? {
        let codeText = try! content.remove(pattern: ";").deleteBlankCharacter
        guard let typeInfo = findPropertyTypeRE.firstMatch(in: codeText) else { return nil }
//        let type: PropertyType!
        var units: PropertyUnit = []
        var startIndex = typeInfo.range.upperBound
        switch typeInfo.str {
        case "@property":
//            type = .property
            if var unitText = findPropertyUnitRE.firstMatch(in: codeText) {
                unitText.str = try! unitText.str.remove(pattern: "(\\s|\\(|\\))")
                let unitStrSet = unitText.str.split(separator: ",")
                for unitStr in unitStrSet {
                    let _unit = PropertyUnit(rawValue: String(unitStr))
                    units.insert(_unit)
                }
                startIndex = unitText.range.upperBound
            }
        case "@synthesize":
//            type = .synthesize
            var synthesizeValue = String(codeText[typeInfo.range.upperBound ..< codeText.endIndex])
            synthesizeValue = try! synthesizeValue.remove(pattern: "\\s")
            let synthesizeSet = synthesizeValue.split(separator: ",")
            var propertySet = [PropertyInfo]()
            for str in synthesizeSet {
                if str.count == 0 { continue }
                let equalMark = "="
                let tmpStr = String(str)
                guard let name = tmpStr.substring(to: equalMark, includeMark: false),
                      !name.isEmpty,
                      let variableName = tmpStr.substring(from: equalMark, includeMark: false),
                      !variableName.isEmpty
                      else { continue }
                propertySet.append(
                    PropertyInfo(name: name, instanceVariableName: variableName)
                )
            }
            return propertySet
        case "@dynamic":
//            type = .dynamic
            var dynamicValue = String(codeText[typeInfo.range.upperBound ..< codeText.endIndex])
            dynamicValue = try! dynamicValue.remove(pattern: "\\s")
            let dynamicStrSet = dynamicValue.split(separator: ",")
            var propertySet = [PropertyInfo]()
            for str in dynamicStrSet {
                if str.isEmpty { continue }
                propertySet.append(PropertyInfo(name: String(str)))
            }
            return propertySet
        default:
            return nil
        }
        let variableStr = String(codeText[startIndex ..< codeText.endIndex]).deleteBlankCharacter
        var name = String()
        var className = String()
        for (index, char) in variableStr.reversed().enumerated() {
            if (char == "*" || char == " " || char == "\n") && !name.isEmpty {
                className = variableStr.substring(to: variableStr.count - index) ?? ""
                break
            }
            name.insert(char, at: name.startIndex)
        }
        if name.isEmpty || className.isEmpty { return nil }
        let isExistPointerMark = className.hasSuffix("*")
        if isExistPointerMark {
            className.removeLast()
            className = className.deleteBlankCharacter
        }
        let actualClassName = className.substring(to: "<", includeMark: false) ?? className
        let declarClassName = className.substring(to: "<")
        return [PropertyInfo(
            unit: units,
            name: name,
            className: className,
            declarClassName: declarClassName,
            actualClassName: actualClassName,
            isExistPointerMark: isExistPointerMark
        )]
    }
}
