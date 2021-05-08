//
//  PropertyInfo.swift
//  GMLXcodePlugin
//
//  Created by GML on 2021/4/27.
//

import Foundation

enum PropertyType {
    case property
    case synthesize
    case dynamic
    /// 合并后的属性类型
    case complex
}

struct PropertyUnit : OptionSet {
    static var atomic = PropertyUnit(rawValue: "atomic")
    static var nonatomic = PropertyUnit(rawValue: "nonatomic")
    static var copy = PropertyUnit(rawValue: "copy")
    static var strong = PropertyUnit(rawValue: "strong")
    static var assgin = PropertyUnit(rawValue: "assgin")
    static var weak = PropertyUnit(rawValue: "weak")
    static var nullable = PropertyUnit(rawValue: "nullable")
    static var readonly = PropertyUnit(rawValue: "readonly")
    static var readwrite = PropertyUnit(rawValue: "readwrite")
    
    var rawValue: String { rawValueSet.joined(separator: ", ") }
    private(set) var rawValueSet: Set<String>
    init() {
        self.init(rawValue: "")
    }
    init(rawValue: String) {
        rawValueSet = Set(arrayLiteral: rawValue)
    }
    //MARK:- SetAlgebra
    mutating func formUnion(_ other: __owned PropertyUnit) {
        rawValueSet.formUnion(other.rawValueSet)
    }
    mutating func formIntersection(_ other: PropertyUnit) {
        rawValueSet.formIntersection(other.rawValueSet)
    }
    mutating func formSymmetricDifference(_ other: __owned PropertyUnit) {
        rawValueSet.formSymmetricDifference(other.rawValueSet)
    }
}

struct PropertyInfo {
    let type: PropertyType
    let unit: PropertyUnit?
    
    let name: String
    /// 定义的类全名
    let className: String?
    /// 范型声明
    let declarClassName: String?
    /// 实际类名
    let actualClassName: String?
    let isExistPointerMark: Bool?
    let instanceVariableName: String?
    
    /// dynamic 标识属性生成器
    init(name: String) {
        type = .dynamic
        self.name = name
        unit = nil
        className = nil
        declarClassName = nil
        actualClassName = nil
        isExistPointerMark = nil
        instanceVariableName = nil
    }
    
    /// synthesize 标识属性生成器
    init(name: String, instanceVariableName: String) {
        type = .synthesize
        self.name = name
        unit = nil
        className = nil
        declarClassName = nil
        actualClassName = nil
        isExistPointerMark = nil
        self.instanceVariableName = instanceVariableName
    }
    
    /// property 标识属性生成器
    init(unit: PropertyUnit?,
         name: String,
         className: String?,
         declarClassName: String?,
         actualClassName: String?,
         isExistPointerMark: Bool) {
        type = .property
        self.name = name
        self.unit = unit
        self.className = className
        self.declarClassName = declarClassName
        self.actualClassName = actualClassName
        self.isExistPointerMark = isExistPointerMark
        instanceVariableName = nil
    }
    init(type: PropertyType,
         unit: PropertyUnit?,
         name: String,
         className: String?,
         declarClassName: String?,
         actualClassName: String?,
         isExistPointerMark: Bool?,
         instanceVariableName: String?) {
        self.type = type
        self.name = name
        self.unit = unit
        self.className = className
        self.declarClassName = declarClassName
        self.actualClassName = actualClassName
        self.isExistPointerMark = isExistPointerMark
        self.instanceVariableName = instanceVariableName
    }
    
    func merge(info: Self) -> Self {
        if name != info.name { return self }
        return PropertyInfo(
            type: type == info.type ? type : .complex,
            unit: unit ?? info.unit,
            name: name,
            className: className ?? info.className,
            declarClassName: declarClassName ?? info.declarClassName,
            actualClassName: actualClassName ?? info.actualClassName,
            isExistPointerMark: isExistPointerMark ?? info.isExistPointerMark,
            instanceVariableName: instanceVariableName ?? info.instanceVariableName)
    }
}
