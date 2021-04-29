//
//  AnalysisConfiguration.swift
//  GMLXcodeTool
//
//  Created by GML on 2021/4/27.
//

import Foundation

struct FileAnalysisConfiguration {
    // 获取全部代码，只读属性，固定值 true
    var isGetFullCode: Bool { true }
//    /// 获取导入头文件
//    var isGetImport: Bool
//    /// 获取全局变量
//    var isGetGlobalVariable: Bool
//    /// 获取定义的宏
//    var isGetDefinedMacro: Bool
//    /// 是否获取类型声明，一般使用 @class @protocol 声明的数据
//    var isGetTypeDeclaration: Bool
//    /// 是否获取使用 typedef 类型定义
//    var isGetTypedef: Bool
    
    /// 导入的头文件解析配置
    var `import`: ImportAnalysisConfiguration?
    /// 全局变量解析配置
    var globalVariable: GlobalVariableAnalysisConfiguration?
    /// 宏解析配置
    var macro: MacroAnalysisConfiguration?
    /// 类型声明解析配置
    var typeDeclaration: TypeDeclarationAnalysisConfiguration?
    /// 类型定义解析配置
    var typedef: TypedefAnalysisConfiguration?
    /// 解析解析配置
    var `protocol`: ProtocolAnalysisConfiguration?
    /// 类解析配置
    var `class`: ClassAnalysisConfiguration?
    
    static var `default` : FileAnalysisConfiguration {
        return FileAnalysisConfiguration(
            import: nil,
            globalVariable: nil,
            macro: nil,
            typeDeclaration: nil,
            typedef: nil,
            protocol: nil,
            class: nil
        )
    }
}

struct ImportAnalysisConfiguration {

}
struct GlobalVariableAnalysisConfiguration {
    
}
struct MacroAnalysisConfiguration {
    
}
struct TypeDeclarationAnalysisConfiguration {
    
}
struct TypedefAnalysisConfiguration {
    
}
struct ProtocolAnalysisConfiguration {
    
}
struct ClassAnalysisConfiguration {
    /// 获取类基础信息包括类类型/类名/扩展名
    var isGetClassInfo: Bool
//    /// 获取遵守的协议
//    var isGetProtocol: Bool
//    /// 获取实例变量
//    var isGetInstanceVariable: Bool
//    /// 获取属性
//    var isGetProperty: Bool
//    /// 获取方法
//    var isGetMethod: Bool
    /// 属性详细解析配置
    var propertyAnalysisConfiguration: PropertyAnalysisConfiguration?
    /// 方法详细解析配置
    var methodAnalysisConfiguration: MethodAnalysisConfiguration?
    
    static var `default`: ClassAnalysisConfiguration {
        return ClassAnalysisConfiguration(
            isGetClassInfo: true,
            propertyAnalysisConfiguration: nil,
            methodAnalysisConfiguration: nil
        )
    }
}

struct PropertyAnalysisConfiguration {
    
}
struct MethodAnalysisConfiguration {
    
}
