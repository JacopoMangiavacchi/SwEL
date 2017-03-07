//
//  ConditionParser.swift
//  ConditionParser
//
//  Version 0.2
//
//  Created by Jacopo Mangiavacchi on 25/02/2017.
//  Copyright © 2017 Jacopo Mangiavacchi. All rights reserved.
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/JacopoMangiavacchi/SwiftConditionParser
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//
//
//  For evaluating numeric expressions inside the AND/OR conditions this package
//  use Expression software that is Copyright (c) 2016 Nick Lockwood
//  (see Expression.swift)
//

import Foundation

/// ConditionError is throwed by *checkCondition()* if the condition string is not well formed
///
/// - invalidSyntax: generic error
/// - unclosedBracket: a round bracket has been opened but not closed
/// - invalidOperator: operator is different than ==, !=, >, >=, <, <=
/// - invalidOperand: operand is a string literal beginning with " or ' but not ending with the same symbol
/// - differentOperandTypes: the condition is comparing two operand of different type (Int, Double or String)
/// - invalidOperandType: operand type different than Int, Double or String
/// - invalidCondition: condition is different than && or ||
/// - wrongNumberParametersToFunction: an expression function has been called with wrong number of parameters
///
public enum ConditionError : Error {
    case invalidSyntax
    case unclosedBracket
    case invalidOperator
    case invalidOperand
    case differentOperandTypes
    case invalidOperandType
    case invalidCondition
    case wrongNumberParametersToFunction
    case invalidFunction
}

fileprivate enum ConditionOperator : String {
    case equal = "=="
    case different = "!="
    case greater = ">"
    case greaterEqual = ">="
    case less = "<"
    case lessEqual = "<="
}

fileprivate enum ConditionBracket : String {
    case open = "("
    case close = ")"
}

fileprivate enum ConditionLogicOperator : String {
    case or = "||"
    case and = "&&"
}

fileprivate enum ConditionFunction : String {
    case intFunction = "Int("
    case doubleFunction = "Double("
    case searchFunction = "Search("         // Search("text", "regex")
    case substringFunction = "Substring("   // Substring("text", "regex")
}

fileprivate enum ConditionStatus {
    case clear
    case inBracketCondition
    case inConditionLeftOperand
    case inConditionOperator
    case inConditionRightOperand
    case inCondition
}


extension Dictionary {
    func mapDictionary(transform: (Key, Value) -> (Key, Value)?) -> Dictionary<Key, Value> {
        var dict = [Key: Value]()
        for key in keys {
            guard let value = self[key], let keyValue = transform(key, value) else {
                continue
            }
            
            dict[keyValue.0] = keyValue.1
        }
        return dict
    }
}


extension String {
    
    /// *checkCondition()* evaluate complex conditions with AND/OR, infinite level of brackets and dynamic
    /// bindings to parameters from any String at runtime
    ///
    /// *example 1*:  try! "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkCondition()
    ///
    /// *example 2*:  try! "var1 == var2".checkCondition(withVariables: ["var1" : 1, "var2" : 2])
    ///
    /// - Parameter variables: optional Dictionary of variables to bind values to parameter name in the condition string
    ///
    /// - Returns: A Bool indicating the result of the condition
    ///
    /// - Throws: ConditionError if condition string is not well formed (i.e. contain wrong number of brackets, wrong operators (==, !=, <, <=, >, >=, wrong conditions (&& or ||) or if comparing different data types (Integer, Double, String)
    ///
    public func checkCondition(withVariables variables: [String : Any]? = nil) throws -> Bool {
        var previousCondition = true
        
        var status = ConditionStatus.clear
        
        var innerCondition = ""
        var innerBracketCounter = 0
        var inOperandBracketCounter = 0
        var condLeftOperand = ""
        var condRightOperand = ""
        var condOperator = ""
        var condition = ""
        
        var validOperator:ConditionOperator!
        
        func clear() {
            status = .clear
            innerCondition = ""
            innerBracketCounter = 0
            inOperandBracketCounter = 0
            condLeftOperand = ""
            condRightOperand = ""
            condOperator = ""
            condition = ""
        }
        
        func openBracket() {
            status = .inBracketCondition
            innerCondition = ""
            innerBracketCounter = 1
        }
        
        func closeBracket() {
            status = .inCondition
            innerCondition = ""
            innerBracketCounter = 0
        }
        
        func getLeftOperand() {
            status = .inConditionLeftOperand
            condLeftOperand = ""
            condRightOperand = ""
            condOperator = ""
            inOperandBracketCounter = 0
        }
        
        func getOperator() {
            status = .inConditionOperator
            condOperator = ""
        }
        
        func getRightOperand() {
            status = .inConditionRightOperand
            condRightOperand = ""
            inOperandBracketCounter = 0
        }
        
        func closeCondition() {
            status = .inCondition
            innerCondition = ""
            innerBracketCounter = 0
            inOperandBracketCounter = 0
            condLeftOperand = ""
            condRightOperand = ""
            condOperator = ""
            condition = ""
        }
        
        func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
            var i = 0
            return AnyIterator {
                let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
                if next.hashValue != i { return nil }
                i += 1
                return next
            }
        }
        
        func getValidOperator(_ op: String) throws -> ConditionOperator {
            var valid = false
            
            for validOp in iterateEnum(ConditionOperator.self) {
                if op == validOp.rawValue {
                    valid = true
                    break
                }
            }
            
            if valid {
                return ConditionOperator(rawValue: op)!
            }
            else {
                throw ConditionError.invalidOperator
            }
        }
        
        func compareInt(left: Int, right: Int, op: ConditionOperator) -> Bool {
            switch op {
            case .equal:
                if left == right {
                    return true
                }
            case .different:
                if left != right {
                    return true
                }
            case .greater:
                if left > right {
                    return true
                }
            case .greaterEqual:
                if left >= right {
                    return true
                }
            case .less:
                if left < right {
                    return true
                }
            case .lessEqual:
                if left <= right {
                    return true
                }
            }
            
            return false
        }
        
        func compareString(left: String, right: String, op: ConditionOperator) -> Bool {
            switch op {
            case .equal:
                if left == right {
                    return true
                }
            case .different:
                if left != right {
                    return true
                }
            case .greater:
                if left > right {
                    return true
                }
            case .greaterEqual:
                if left >= right {
                    return true
                }
            case .less:
                if left < right {
                    return true
                }
            case .lessEqual:
                if left <= right {
                    return true
                }
            }
            
            return false
        }
        
        func compareDouble(left: Double, right: Double, op: ConditionOperator) -> Bool {
            switch op {
            case .equal:
                if left == right {
                    return true
                }
            case .different:
                if left != right {
                    return true
                }
            case .greater:
                if left > right {
                    return true
                }
            case .greaterEqual:
                if left >= right {
                    return true
                }
            case .less:
                if left < right {
                    return true
                }
            case .lessEqual:
                if left <= right {
                    return true
                }
            }
            
            return false
        }
        
        func calculateExpression(_ expression: String) throws -> Double {
            //Convert Dictionary variables: [String : Any]?  ==>  constants: [String: Double]?
            let constants: [String: Double]? = variables?.mapDictionary { (k,v) in
                if let d = v as? Double {
                    return (k, d)
                }
                else if let i = v as? Int {
                    return (k, Double(i))
                }
                return nil
                } as! [String : Double]?
            
            return try Expression(expression, constants: constants).evaluate()
        }
        
        func search(text: String, regexp: String) -> Int {
            if let range = text.range(of:regexp, options: .regularExpression) {
                return text.distance(from: text.startIndex, to: range.lowerBound)
            }
            
            return -1
        }
        
        func searchUpperCase(text: String, regexp: String) -> Int {
            return search(text: text.uppercased(), regexp: regexp)
        }
        
        func searchLowerCase(text: String, regexp: String) -> Int {
            return search(text: text.lowercased(), regexp: regexp)
        }
        
        func substring(text: String, regexp: String) -> String {
            if let range = text.range(of:regexp, options: .regularExpression) {
                return text.substring(with:range)
            }
            
            return ""
        }
        
        func substringUpperCase(text: String, regexp: String) -> String {
            return substring(text: text.uppercased(), regexp: regexp)
        }
        
        func substringLowerCase(text: String, regexp: String) -> String {
            return substring(text: text.lowercased(), regexp: regexp)
        }
        
        func substring(text: String, from: Int, to: Int) -> String {
            
            return ""
        }
        
        func substringUpperCase(text: String, from: Int, to: Int) -> String {
            return substring(text: text.uppercased(), from: from, to: to)
        }
        
        func substringLowerCase(text: String, from: Int, to: Int) -> String {
            return substring(text: text.lowercased(), from: from, to: to)
        }
        
        func getStringParameters(buffer: String) -> [String] {
            var parameters = buffer.components(separatedBy: ",")

            for i in 0..<parameters.count {
                var parameter = parameters[i]
                
                parameter = parameter.trimmingCharacters(in: CharacterSet.whitespaces)
                
                if parameter.hasPrefix("'") && parameter.hasSuffix("'") {
                    parameter = parameter.replacingOccurrences(of: "'", with: "")
                }
                else if parameter.hasPrefix("\"") && parameter.hasSuffix("\"") {
                    parameter = parameter.replacingOccurrences(of: "\"", with: "")
                }
                else if let variable = variables?[parameter] as? String {
                    parameter = variable
                }
                
                parameters[i] = parameter
            }
            
            return parameters
        }
        
        
        func evaluateOperand(operand: String) throws -> Any {
            guard !operand.isEmpty else {
                throw ConditionError.invalidOperand
            }
            
            if let intOperand = Int(operand) {
                return intOperand
            }
            else if let doubleOperand = Double(operand) {
                return doubleOperand
            }
            else {
                if operand.hasPrefix("'") {
                    if !operand.hasSuffix("'") {
                        throw ConditionError.invalidOperand
                    }
                    
                    return operand.replacingOccurrences(of: "'", with: "")
                }
                else if operand.hasPrefix("\"") {
                    if !operand.hasSuffix("\"") {
                        throw ConditionError.invalidOperand
                    }
                    
                    return operand.replacingOccurrences(of: "\"", with: "")
                }
                else if let range = operand.range(of: "(") {
                    if !operand.hasSuffix(")") {
                        throw ConditionError.invalidOperand
                    }
                    
                    let functionNameRange = Range<String.Index>(uncheckedBounds: (lower: operand.startIndex, upper: range.upperBound))
                    let functionName = operand.substring(with:functionNameRange)
                    
                    let endIndex = operand.index(operand.endIndex, offsetBy: -2)
                    let functionParameters = operand[range.upperBound...endIndex]
                    
                    if let function = ConditionFunction(rawValue: functionName) {
                        switch function {
                        case .intFunction:
                            return try Int(calculateExpression(functionParameters))
                            
                        case .doubleFunction:
                            return try calculateExpression(functionParameters)
                            
                        case .searchFunction:
                            let parameters = getStringParameters(buffer: functionParameters)
                            
                            guard parameters.count == 2 else {
                                throw ConditionError.wrongNumberParametersToFunction
                            }
                            
                            return search(text: parameters[0], regexp: parameters[1])
                            
                        case .substringFunction:
                            let parameters = getStringParameters(buffer: functionParameters)
                            
                            guard parameters.count == 2 else {
                                throw ConditionError.wrongNumberParametersToFunction
                            }
                            
                            return substring(text: parameters[0], regexp: parameters[1])
                        }
                    }
                    else {
                        throw ConditionError.invalidFunction
                    }
                }
                else {
                    if let variable = variables?[operand] {
                        return variable
                    }
                    throw ConditionError.invalidOperand
                }
            }
        }
        
        func evaluateCondition(left: String, op: ConditionOperator, right: String) throws -> Bool {
            let leftValue = try evaluateOperand(operand: left)
            let rightValue = try evaluateOperand(operand: right)
            
            guard type(of: leftValue) == type(of: rightValue) else {
                throw ConditionError.differentOperandTypes
            }
            
            var equal = false
            
            switch "\(type(of: leftValue))" {
            case "Int":
                equal = compareInt(left: leftValue as! Int, right: rightValue as! Int, op: op)
                
            case "String":
                equal = compareString(left: leftValue as! String, right: rightValue as! String, op: op)
                
            case "Double":
                equal = compareDouble(left: leftValue as! Double, right: rightValue as! Double, op: op)
                
            default:
                throw ConditionError.invalidOperandType
            }
            
            
            return equal
        }
        
        func evaluateCondition(condition: String) throws -> ConditionLogicOperator {
            var valid = false
            
            for validOp in iterateEnum(ConditionLogicOperator.self) {
                if condition == validOp.rawValue {
                    valid = true
                    break
                }
            }
            
            if valid {
                return ConditionLogicOperator(rawValue: condition)!
            }
            else {
                throw ConditionError.invalidCondition
            }
        }
        
        
        //START
        
        clear()
        for index in self.characters.indices {
            let lastIndex = (index == self.characters.indices.index(before: self.characters.indices.endIndex) ? true : false)
            let value = String(self[index])
            
            switch status {
            case .clear:
                if value == ConditionBracket.open.rawValue {
                    openBracket()
                }
                else if value == " " {
                    //nop
                }
                else {
                    getLeftOperand()
                    condLeftOperand.append(value)
                }
                
            case .inBracketCondition:
                if value == ConditionBracket.open.rawValue {
                    innerBracketCounter += 1
                    innerCondition.append(value)
                }
                else {
                    if value == ConditionBracket.close.rawValue {
                        innerBracketCounter -= 1
                    }
                    
                    if innerBracketCounter == 0 {
                        previousCondition = try innerCondition.checkCondition(withVariables: variables)
                        
                        closeBracket()
                    }
                    else {
                        innerCondition.append(value)
                    }
                }
                
            case .inConditionLeftOperand:
                if value == ConditionBracket.open.rawValue {
                    inOperandBracketCounter += 1
                }
                if value == ConditionBracket.close.rawValue {
                    inOperandBracketCounter -= 1
                }
                
                if value == " " && inOperandBracketCounter == 0 {
                    getOperator()
                }
                else {
                    condLeftOperand.append(value)
                }
                
            case .inConditionOperator:
                if value == " " {
                    if !condOperator.isEmpty {
                        validOperator = try getValidOperator(condOperator)
                        getRightOperand()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    condOperator.append(value)
                }
                
            case .inConditionRightOperand:
                if value == ConditionBracket.open.rawValue {
                    inOperandBracketCounter += 1
                }
                if value == ConditionBracket.close.rawValue {
                    inOperandBracketCounter -= 1
                }
                
                if (value == " " && inOperandBracketCounter == 0) || lastIndex {
                    if value != " " && lastIndex {
                        condRightOperand.append(value)
                    }
                    
                    if !condRightOperand.isEmpty {
                        previousCondition = try evaluateCondition(left: condLeftOperand, op: validOperator, right: condRightOperand)
                        closeCondition()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    condRightOperand.append(value)
                }
                
            case .inCondition:
                if value == " "  || lastIndex {
                    if value != " " && lastIndex {
                        condition.append(value)
                    }
                    
                    if !condition.isEmpty {
                        let realCondition = try evaluateCondition(condition: condition)
                        
                        if realCondition == .and && !previousCondition {
                            return false
                        }
                        if realCondition == .or && previousCondition {
                            return true
                        }
                        
                        clear()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    condition.append(value)
                }
            }
        }
        
        if status != .inCondition || !condition.isEmpty {
            if status == .inBracketCondition {
                throw ConditionError.unclosedBracket
            }
            
            throw ConditionError.invalidSyntax
        }
        
        return previousCondition
    }
}
