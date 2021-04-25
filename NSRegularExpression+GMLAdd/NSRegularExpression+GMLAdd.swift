//
//  NSRegularExpression+GMLAdd.swift
//  GMLClassAnalysis
//
//  Created by GML on 2021/4/24.
//

import Foundation

extension NSRegularExpression {
    convenience init(pattern: String) {
        do {
            try self.init(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
        } catch {
            assert(false, pattern)
            self.init() // 占位代码，永远不会执行
        }
    }
}
