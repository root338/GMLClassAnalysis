//
//  NSRegularExpression+GMLAdd.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/24.
//

import Foundation

extension NSRegularExpression {
//    convenience init(pattern: String) {
//        do {
//            try self.init(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
//        } catch {
//            assert(false, pattern)
//            self.init() // 占位代码，永远不会执行
//        }
//    }
    func firstMatch(in string: String) -> (str: String, range: Range<String.Index>)? {
        guard let result = firstMatch(in: string, range: NSMakeRange(0, string.count)),
              let range = Range(result.range, in: string)
        else {
            return nil
        }
        return (String(string[range]), range)
    }
}
