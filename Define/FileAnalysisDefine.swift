//
//  FileAnalysisDefine.swift
//  GMLXcodeTool
//
//  Created by GML on 2021/4/27.
//

import Foundation

struct FileAnalysisConstant {
    static var `import`: String { "@import" }
    static var interface: String { "@interface" }
    static var implementation: String { "@implementation" }
    static var end: String { "@end" }
    static var property: String { "@property" }
    static var synthesize: String { "@synthesize" }
    static var dynamic: String { "@dynamic" }
    /// 合法字符包含空白字符
    static var legalCharactersAndBlankPattern: String { "[\\sa-zA-Z0-9_]" }
    /// 合法字符
    static var legalCharactersPattern: String { "[a-zA-Z0-9_]" }
}
extension String {
    func removeKeywordMark() -> String {
        var str = self;
        if self.hasPrefix("@") {
            str.removeFirst()
        }
        return str
    }
}
