//
//  ExpressionParser.swift
//  ExpressionParser
//
//  Version 0.1
//
//  Created by Jacopo Mangiavacchi on 25/02/2017.
//  Copyright © 2017 Jacopo Mangiavacchi. All rights reserved.
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/JacopoMangiavacchi/Swift-Expression-Parser
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
//  For evaluating numeric expressions inside the AND/OR expression conditions
//  this Package use Expression software that is Copyright (c) 2016 Nick Lockwood
//  (see Expression.swift)
//

import Foundation

/// ExpressionError is throwed by *checkExpression()* if the expression string is not well formed
///
/// - invalidSyntax: generic error
/// - unclosedBracket: a round bracket has been opened but not closed
/// - invalidOperator: operator is different than ==, !=, >, >=, <, <=
/// - invalidOperand: operand is a string literal beginning with " or ' but not ending with the same symbol
/// - differentOperandTypes: the expression is comparing two operand of different type (Int, Double or String)
/// - invalidOperandType: operand type different than Int, Double or String
/// - invalidCondition: condition is different than && or ||
///
public enum ExpressionError : Error {
    case invalidSyntax
    case unclosedBracket
    case invalidOperator
    case invalidOperand
    case differentOperandTypes
    case invalidOperandType
    case invalidCondition
}

fileprivate enum ExpressionOperator : String {
    case equal = "=="
    case different = "!="
    case greater = ">"
    case greaterEqual = ">="
    case less = "<"
    case lessEqual = "<="
}

fileprivate enum ExpressionBracket : String {
    case open = "("
    case close = ")"
}

fileprivate enum ExpressionCondition : String {
    case or = "||"
    case and = "&&"
}

fileprivate enum ExpressionFunction : String {
    case intFunction = "Int("
    case doubleFunction = "Double("
}

fileprivate enum ExpressionStatus {
    case clear
    case inBracketExpression
    case inExpressionLeftOperand
    case inExpressionOperator
    case inExpressionRightOperand
    case inCondition
}



extension String {
    
    /// *checkExpression()* evaluate complex expressions with AND/OR conditions
    /// and Dynamic bindings to parameters from any String at runtime
    ///
    /// *example 1*:  try! "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkExpression()
    ///
    /// *example 2*:  try! "var1 == var2".checkExpression(withVariables: ["var1" : 1, "var2" : 2])
    ///
    /// - Parameter variables: optional Dictionary of variables to bind values to parameter name in the expression string
    ///
    /// - Returns: A Bool indicating the result of the expression
    ///
    /// - Throws: ExpressionError if expression string is not well formed (i.e. contain wrong number of brackets, wrong operators (==, !=, <, <=, >, >=, wrong conditions (&& or ||) or if comparing different data types (Integer, Double, String)
    ///
    public func checkExpression(withVariables variables: [String : Any]? = nil) throws -> Bool {
        var previousExpression = true
        
        var status = ExpressionStatus.clear
        
        var innerExpression = ""
        var innerBracketCounter = 0
        var inOperandBracketCounter = 0
        var expLeftOperand = ""
        var expRightOperand = ""
        var expOperator = ""
        var condition = ""
        
        var validOperator:ExpressionOperator!
        
        func clear() {
            status = .clear
            innerExpression = ""
            innerBracketCounter = 0
            inOperandBracketCounter = 0
            expLeftOperand = ""
            expRightOperand = ""
            expOperator = ""
            condition = ""
        }
        
        func openBracket() {
            status = .inBracketExpression
            innerExpression = ""
            innerBracketCounter = 1
        }
        
        func closeBracket() {
            status = .inCondition
            innerExpression = ""
            innerBracketCounter = 0
        }
        
        func getLeftOperand() {
            status = .inExpressionLeftOperand
            expLeftOperand = ""
            expRightOperand = ""
            expOperator = ""
            inOperandBracketCounter = 0
        }
        
        func getOperator() {
            status = .inExpressionOperator
            expOperator = ""
        }
        
        func getRightOperand() {
            status = .inExpressionRightOperand
            expRightOperand = ""
            inOperandBracketCounter = 0
        }
        
        func closeExpression() {
            status = .inCondition
            innerExpression = ""
            innerBracketCounter = 0
            inOperandBracketCounter = 0
            expLeftOperand = ""
            expRightOperand = ""
            expOperator = ""
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
        
        func getValidOperator(_ op: String) throws -> ExpressionOperator {
            var valid = false
            
            for validOp in iterateEnum(ExpressionOperator.self) {
                if op == validOp.rawValue {
                    valid = true
                    break
                }
            }
            
            if valid {
                return ExpressionOperator(rawValue: op)!
            }
            else {
                throw ExpressionError.invalidOperator
            }
        }
        
        func compareInt(left: Int, right: Int, op: ExpressionOperator) -> Bool {
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
        
        func compareString(left: String, right: String, op: ExpressionOperator) -> Bool {
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
        
        func compareDouble(left: Double, right: Double, op: ExpressionOperator) -> Bool {
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
            
            print(expression)
            
            return try Expression(expression).evaluate()
        }
        
        func evaluateOperand(operand: String) throws -> Any {
            guard !operand.isEmpty else {
                throw ExpressionError.invalidOperand
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
                        throw ExpressionError.invalidOperand
                    }
                    
                    return operand.replacingOccurrences(of: "'", with: "")
                }
                else if operand.hasPrefix("\"") {
                    if !operand.hasSuffix("\"") {
                        throw ExpressionError.invalidOperand
                    }
                    
                    return operand.replacingOccurrences(of: "\"", with: "")
                }
                else if operand.hasPrefix(ExpressionFunction.intFunction.rawValue) {
                    if !operand.hasSuffix(")") {
                        throw ExpressionError.invalidOperand
                    }
                    
                    let startIndex = operand.index(operand.startIndex, offsetBy: ExpressionFunction.intFunction.rawValue.characters.count)
                    let endIndex = operand.index(operand.endIndex, offsetBy: -2)
                    
                    return try Int(calculateExpression(operand[startIndex...endIndex]))
                }
                else if operand.hasPrefix(ExpressionFunction.doubleFunction.rawValue) {
                    if !operand.hasSuffix(")") {
                        throw ExpressionError.invalidOperand
                    }
                    
                    let startIndex = operand.index(operand.startIndex, offsetBy: ExpressionFunction.doubleFunction.rawValue.characters.count)
                    let endIndex = operand.index(operand.endIndex, offsetBy: -2)
                    
                    return try calculateExpression(operand[startIndex...endIndex])
                }
                else {
                    if let variable = variables?[operand] {
                        return variable
                    }
                    throw ExpressionError.invalidOperand
                }
            }
        }
        
        func evaluateExpression(left: String, op: ExpressionOperator, right: String) throws -> Bool {
            let leftValue = try evaluateOperand(operand: left)
            let rightValue = try evaluateOperand(operand: right)
            
            guard type(of: leftValue) == type(of: rightValue) else {
                throw ExpressionError.differentOperandTypes
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
                throw ExpressionError.invalidOperandType
            }
            
            
            return equal
        }
        
        func evaluateCondition(condition: String) throws -> ExpressionCondition {
            var valid = false
            
            for validOp in iterateEnum(ExpressionCondition.self) {
                if condition == validOp.rawValue {
                    valid = true
                    break
                }
            }
            
            if valid {
                return ExpressionCondition(rawValue: condition)!
            }
            else {
                throw ExpressionError.invalidCondition
            }
        }
        
        
        //START
        
        clear()
        for index in self.characters.indices {
            let lastIndex = (index == self.characters.indices.index(before: self.characters.indices.endIndex) ? true : false)
            let value = String(self[index])
            
            switch status {
            case .clear:
                if value == ExpressionBracket.open.rawValue {
                    openBracket()
                }
                else if value == " " {
                    //nop
                }
                else {
                    getLeftOperand()
                    expLeftOperand.append(value)
                }
                
            case .inBracketExpression:
                if value == ExpressionBracket.open.rawValue {
                    innerBracketCounter += 1
                    innerExpression.append(value)
                }
                else {
                    if value == ExpressionBracket.close.rawValue {
                        innerBracketCounter -= 1
                    }
                    
                    if innerBracketCounter == 0 {
                        previousExpression = try innerExpression.checkExpression(withVariables: variables)
                        
                        closeBracket()
                    }
                    else {
                        innerExpression.append(value)
                    }
                }
                
            case .inExpressionLeftOperand:
                if value == ExpressionBracket.open.rawValue {
                    inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    inOperandBracketCounter -= 1
                }
                
                if value == " " && inOperandBracketCounter == 0 {
                    getOperator()
                }
                else {
                    expLeftOperand.append(value)
                }
                
            case .inExpressionOperator:
                if value == " " {
                    if !expOperator.isEmpty {
                        validOperator = try getValidOperator(expOperator)
                        getRightOperand()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    expOperator.append(value)
                }
                
            case .inExpressionRightOperand:
                if value == ExpressionBracket.open.rawValue {
                    inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    inOperandBracketCounter -= 1
                }
                
                if (value == " " && inOperandBracketCounter == 0) || lastIndex {
                    if value != " " && lastIndex {
                        expRightOperand.append(value)
                    }
                    
                    if !expRightOperand.isEmpty {
                        previousExpression = try evaluateExpression(left: expLeftOperand, op: validOperator, right: expRightOperand)
                        closeExpression()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    expRightOperand.append(value)
                }
                
            case .inCondition:
                if value == " "  || lastIndex {
                    if value != " " && lastIndex {
                        condition.append(value)
                    }
                    
                    if !condition.isEmpty {
                        let realCondition = try evaluateCondition(condition: condition)
                        
                        if realCondition == .and && !previousExpression {
                            return false
                        }
                        if realCondition == .or && previousExpression {
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
            if status == .inBracketExpression {
                throw ExpressionError.unclosedBracket
            }
            
            throw ExpressionError.invalidSyntax
        }
        
        return previousExpression
    }
}



