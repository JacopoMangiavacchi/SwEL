//  SwEL (Swift Expression Language)
//
//  SwEL.swift
//
//  Version 0.4
//
//  Created by Jacopo Mangiavacchi on 25/02/2017.
//  Copyright © 2017 Jacopo Mangiavacchi. All rights reserved.
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/JacopoMangiavacchi/SwEL
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

/// SwELError is throwed by *checkCondition()* or *evalExpression()* if the expression string is not well formed
///
/// - invalidSyntax: generic error
/// - unclosedBracket: a round bracket has been opened but not closed
/// - invalidOperator: operator is different than ==, !=, >, >=, <, <= in Condition or = in Expression
/// - invalidOperand: operand is a string literal beginning with " or ' but not ending with the same symbol
/// - differentOperandTypes: the condition is comparing two operand of different type (Int, Double or String)
/// - invalidOperandType: operand type different than Int, Double or String
/// - invalidCondition: condition is different than && or ||
/// - wrongNumberParametersToFunction: an expression function has been called with wrong number of parameters
/// - invalidFunction: an unsupported function has been called in the expression
///
public enum SwELError : Error {
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

fileprivate enum ExpressionBracket : String {
    case open = "("
    case close = ")"
}

fileprivate enum ConditionLogicOperator : String {
    case or = "||"
    case and = "&&"
}

fileprivate enum ExpressionFunction : String {
    case intFunction = "int("                           // int("math expression") -> Int
    case doubleFunction = "double("                     // double("math expression") -> Double
    case searchFunction = "search("                     // search("text", "regex") -> Int
    case searchUpperFunction = "searchUpper("           // searchUpper("text", "regex") -> Int
    case searchLowerFunction = "searchLower("           // searchLower("text", "regex") -> Int
    case substringFunction = "substring("               // substring("text", "regex") -> String
    case substringUpperFunction = "substringUpper("     // substringUpper("text", "regex") -> String
    case substringLowerFunction = "substringLower("     // substringLower("text", "regex") -> String
}

fileprivate enum ConditionStatus {
    case clear
    case inBracketCondition
    case inConditionLeftOperand
    case inConditionOperator
    case inConditionRightOperand
    case inCondition
}

fileprivate struct ConditionStatusStruct {
    var status = ConditionStatus.clear
    var previousCondition = true
    var innerCondition = ""
    var innerBracketCounter = 0
    var inOperandBracketCounter = 0
    var condLeftOperand = ""
    var condRightOperand = ""
    var condOperator = ""
    var condition = ""
    var validOperator:ConditionOperator!
    
    mutating func clear() {
        status = .clear
        innerCondition = ""
        innerBracketCounter = 0
        inOperandBracketCounter = 0
        condLeftOperand = ""
        condRightOperand = ""
        condOperator = ""
        condition = ""
    }
    
    mutating func openBracket() {
        status = .inBracketCondition
        innerCondition = ""
        innerBracketCounter = 1
    }
    
    mutating func closeBracket() {
        status = .inCondition
        innerCondition = ""
        innerBracketCounter = 0
    }
    
    mutating func getLeftOperand() {
        status = .inConditionLeftOperand
        condLeftOperand = ""
        condRightOperand = ""
        condOperator = ""
        inOperandBracketCounter = 0
    }
    
    mutating func getOperator() {
        status = .inConditionOperator
        condOperator = ""
    }
    
    mutating func getRightOperand() {
        status = .inConditionRightOperand
        condRightOperand = ""
        inOperandBracketCounter = 0
    }
    
    mutating func closeCondition() {
        status = .inCondition
        innerCondition = ""
        innerBracketCounter = 0
        inOperandBracketCounter = 0
        condLeftOperand = ""
        condRightOperand = ""
        condOperator = ""
        condition = ""
    }
}

fileprivate enum ExpressionOperator : String {
    case assign = "="
}

fileprivate enum ExpressionStatus {
    case clear
    case inExpressionLeftOperand
    case inExpressionOperator
    case inExpressionRightOperand
    case finishedExpression
}

fileprivate struct ExpressionStatusStruct {
    var status = ExpressionStatus.clear
    var exprLeftOperand = ""
    var exprRightOperand = ""
    var exprOperator = ""
    var inOperandBracketCounter = 0
    var validOperator:ExpressionOperator!
    
    mutating func clear() {
        status = .clear
        exprLeftOperand = ""
        exprRightOperand = ""
        exprOperator = ""
        inOperandBracketCounter = 0
    }
    
    mutating func getLeftOperand() {
        status = .inExpressionLeftOperand
        exprLeftOperand = ""
        exprRightOperand = ""
        exprOperator = ""
        inOperandBracketCounter = 0
    }
    
    mutating func getOperator() {
        status = .inExpressionOperator
        exprOperator = ""
    }

    mutating func getRightOperand() {
        status = .inExpressionRightOperand
        exprRightOperand = ""
        inOperandBracketCounter = 0
    }
    
    mutating func finishExpression() {
        status = .finishedExpression
    }
}


// Utility Dictionary Extension for transforming the Values of a Dictionary
fileprivate extension Dictionary {
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



/// *SwEL* (Swift Expression Language)
///
/// Check complex conditions with AND/OR, infinite level of brackets and dynamic bindings to parameters from any String at runtime
/// Evaluate complex expression with dynamic bindings to parameters from any String at runtime
///
///     Condition example: 
///         let condition = "(var1 == 2 || 2 < 4) && 'test' != var2"
///         let variables:[String : Any] = ["var1" : 2, "var2" : "ko"]
///         let exp = SwEL(condition, variables: variables)
///         try exp.checkCondition() // return true
///
///     Expression example: 
///         let expression = "result = int(var1 + var2)"
///         let variables:[String : Any] = ["var1" : 2, "var2" : 3]
///         let exp = SwEL(expression, variables: variables)
///         try exp.evalExpression() // return true and insert ("result" : 5) in the SwEL.variables Dictionary properties
///         //exp.variables["result"] == 5
///
public struct SwEL {
    public var expression: String
    public var variables: [String : Any]


    /// *init()* initialize the *expression* and *variables* properties used by the *checkCondition()* method
    ///
    ///     Condition example: 
    ///         let condition = "(var1 == 2 || 2 < 4) && 'test' != var2"
    ///         let variables:[String : Any] = ["var1" : 2, "var2" : "ko"]
    ///         let exp = SwEL(condition, variables: variables)
    ///         try exp.checkCondition() //return true
    ///
    ///     Expression example: 
    ///         let expression = "result = int(var1 + var2)"
    ///         let variables:[String : Any] = ["var1" : 2, "var2" : 3]
    ///         let exp = SwEL(expression, variables: variables)
    ///         try exp.evalExpression() // return true and insert ("result" : 5) in the SwEL.variables Dictionary properties
    ///         //exp.variables["result"] == 5
    ///
    /// - Parameter expression: an expression containing for example a condition to be evaluated with the *checkCondition()* metod
    /// - Parameter variables: optional Dictionary of variables to bind values to parameter name in the condition string
    ///
    public init(_ expression: String, variables: [String : Any]? = nil) {
        self.expression = expression
        self.variables = variables ?? [String : Any]()
    }
    
    /// *checkCondition()* evaluate complex conditions with AND/OR, infinite level of brackets and dynamic bindings to parameters at runtime
    ///
    /// It use public *expression* and *variables* properties passed to the init method
    ///
    ///     Condition example: 
    ///         let condition = "(var1 == 2 || 2 < 4) && 'test' != var2"
    ///         let variables:[String : Any] = ["var1" : 2, "var2" : "ko"]
    ///         let exp = SwEL(condition, variables: variables)
    ///         try exp.checkCondition() //return true
    ///
    /// - Returns: A Bool indicating the result of the condition
    ///
    /// - Throws: SwELError if condition in the *expression* property is not well formatted (i.e. contain wrong number of brackets, wrong operators (==, !=, <, <=, >, >=, wrong conditions (&& or ||) or if comparing different data types (Integer, Double, String)
    ///
    public func checkCondition() throws -> Bool {
        var conditionStatus = ConditionStatusStruct()

        conditionStatus.clear()
        for index in expression.characters.indices {
            let lastIndex = (index == expression.characters.indices.index(before: expression.characters.indices.endIndex) ? true : false)
            let value = String(expression[index])
            
            switch conditionStatus.status {
            case .clear:
                if value == ExpressionBracket.open.rawValue {
                    conditionStatus.openBracket()
                }
                else if value == " " {
                    //nop
                }
                else {
                    conditionStatus.getLeftOperand()
                    conditionStatus.condLeftOperand.append(value)
                }
                
            case .inBracketCondition:
                if value == ExpressionBracket.open.rawValue {
                    conditionStatus.innerBracketCounter += 1
                    conditionStatus.innerCondition.append(value)
                }
                else {
                    if value == ExpressionBracket.close.rawValue {
                        conditionStatus.innerBracketCounter -= 1
                    }
                    
                    if conditionStatus.innerBracketCounter == 0 {
                        conditionStatus.previousCondition = try conditionStatus.innerCondition.checkCondition(withVariables: variables)
                        
                        conditionStatus.closeBracket()
                    }
                    else {
                        conditionStatus.innerCondition.append(value)
                    }
                }
                
            case .inConditionLeftOperand:
                if value == ExpressionBracket.open.rawValue {
                    conditionStatus.inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    conditionStatus.inOperandBracketCounter -= 1
                }
                
                if value == " " && conditionStatus.inOperandBracketCounter == 0 {
                    conditionStatus.getOperator()
                }
                else {
                    conditionStatus.condLeftOperand.append(value)
                }
                
            case .inConditionOperator:
                if value == " " {
                    if !conditionStatus.condOperator.isEmpty {
                        conditionStatus.validOperator = try getValidConditionOperator(conditionStatus.condOperator)
                        conditionStatus.getRightOperand()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    conditionStatus.condOperator.append(value)
                }
                
            case .inConditionRightOperand:
                if value == ExpressionBracket.open.rawValue {
                    conditionStatus.inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    conditionStatus.inOperandBracketCounter -= 1
                }
                
                if (value == " " && conditionStatus.inOperandBracketCounter == 0) || lastIndex {
                    if value != " " && lastIndex {
                        conditionStatus.condRightOperand.append(value)
                    }
                    
                    if !conditionStatus.condRightOperand.isEmpty {
                        conditionStatus.previousCondition = try evaluateCondition(left: conditionStatus.condLeftOperand, op: conditionStatus.validOperator, right: conditionStatus.condRightOperand)
                        conditionStatus.closeCondition()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    conditionStatus.condRightOperand.append(value)
                }
                
            case .inCondition:
                if value == " "  || lastIndex {
                    if value != " " && lastIndex {
                        conditionStatus.condition.append(value)
                    }
                    
                    if !conditionStatus.condition.isEmpty {
                        let realCondition = try evaluateCondition(condition: conditionStatus.condition)
                        
                        if realCondition == .and && !conditionStatus.previousCondition {
                            return false
                        }
                        if realCondition == .or && conditionStatus.previousCondition {
                            return true
                        }
                        
                        conditionStatus.clear()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    conditionStatus.condition.append(value)
                }
            }
        }
        
        if conditionStatus.status != .inCondition || !conditionStatus.condition.isEmpty {
            if conditionStatus.status == .inBracketCondition {
                throw SwELError.unclosedBracket
            }
            
            throw SwELError.invalidSyntax
        }
        
        return conditionStatus.previousCondition
    }
    

    /// *evalExpression()* evaluate complex expression with dynamic bindings to parameters from any String at runtime
    ///
    /// It use public *expression* and *variables* properties passed to the init method
    ///
    ///     Expression example (Assignement with Math Functions): 
    ///         let expression = "result = int(var1 + var2)"
    ///         let variables:[String : Any] = ["var1" : 2, "var2" : 3]
    ///         let exp = SwEL(expression, variables: variables)
    ///         try exp.evalExpression() // return true and insert ("result" : 5) in the SwEL.variables Dictionary properties
    ///         //exp.variables["result"] == 5
    ///
    ///     Expression example (Evaluation with String Functions): 
    ///         let expression = "substring('This is a test for testing regexp', regex)"
    ///         let variables:[String : Any] = ["regex" : "test|tost"]
    ///         let exp = SwEL(expression, variables: variables)
    ///         try exp.evalExpression() // return "test"
    ///
    /// - Returns: Any value - return true if an assignement or the result of the expression (options: Bool, Int, Float, String)
    ///
    /// - Throws: SwELError if condition in the *expression* property is not well formatted (i.e. contain wrong number of brackets, wrong operators (==, !=, <, <=, >, >=, wrong conditions (&& or ||) or if comparing different data types (Integer, Double, String)
    ///
    public mutating func evalExpression() throws -> Any {
        var expressionStatus = ExpressionStatusStruct()
        
        expressionStatus.clear()
        for index in expression.characters.indices {
            let lastIndex = (index == expression.characters.indices.index(before: expression.characters.indices.endIndex) ? true : false)
            let value = String(expression[index])
            
            switch expressionStatus.status {
            case .clear:
                if value == " " {
                    //nop
                }
                else {
                    expressionStatus.getLeftOperand()
                    expressionStatus.exprLeftOperand.append(value)
                }
                
            case .inExpressionLeftOperand:
                if value == ExpressionBracket.open.rawValue {
                    expressionStatus.inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    expressionStatus.inOperandBracketCounter -= 1
                }
                
                if value == " " && expressionStatus.inOperandBracketCounter == 0 {
                    expressionStatus.getOperator()
                }
                else {
                    expressionStatus.exprLeftOperand.append(value)
                }
                
            case .inExpressionOperator:
                if value == " " {
                    if !expressionStatus.exprOperator.isEmpty {
                        expressionStatus.validOperator = try getValidExpressionOperator(expressionStatus.exprOperator)
                        expressionStatus.getRightOperand()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    expressionStatus.exprOperator.append(value)
                }
                
            case .inExpressionRightOperand:
                if value == ExpressionBracket.open.rawValue {
                    expressionStatus.inOperandBracketCounter += 1
                }
                if value == ExpressionBracket.close.rawValue {
                    expressionStatus.inOperandBracketCounter -= 1
                }
                
                if (value == " " && expressionStatus.inOperandBracketCounter == 0) || lastIndex {
                    if value != " " && lastIndex {
                        expressionStatus.exprRightOperand.append(value)
                    }
                    
                    if !expressionStatus.exprRightOperand.isEmpty {
                        expressionStatus.finishExpression()
                    }
                    else {
                        //nop
                    }
                }
                else {
                    expressionStatus.exprRightOperand.append(value)
                }
                
            case .finishedExpression:
                if value != " " {
                    throw SwELError.invalidSyntax
                }
            }
        }
        
        if expressionStatus.status == .finishedExpression {
            //it's an assignement
            //“var1 = ‘test’” ->  Bool(true) —— inout parameters[var1] = “test”
            
            variables[expressionStatus.exprLeftOperand] = try evaluateOperand(operand: expressionStatus.exprRightOperand)
            
            return true
        }
        
        if expressionStatus.status == .inExpressionLeftOperand || (expressionStatus.status == .inExpressionOperator && expressionStatus.exprOperator.isEmpty ) {
            //“int(1 +2)” -> Int(3)
            //“‘test’” -> String(“test”)

            return try evaluateOperand(operand: expressionStatus.exprLeftOperand)
        }
        
        throw SwELError.invalidSyntax
    }
    
    
    // Utility Funcs
    private func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
    
    
    // Private Funcs
    private func getValidConditionOperator(_ op: String) throws -> ConditionOperator {
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
            throw SwELError.invalidOperator
        }
    }
    
    private func getValidExpressionOperator(_ op: String) throws -> ExpressionOperator {
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
            throw SwELError.invalidOperator
        }
    }
    
    private func compareInt(left: Int, right: Int, op: ConditionOperator) -> Bool {
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
    
    private func compareString(left: String, right: String, op: ConditionOperator) -> Bool {
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
    
    private func compareDouble(left: Double, right: Double, op: ConditionOperator) -> Bool {
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
    
    private func calculateExpression(_ expression: String) throws -> Double {
        //Convert Dictionary variables: [String : Any]?  ==>  constants: [String: Double]?
        let constants: [String: Double]? = variables.mapDictionary { (k,v) in
            if let d = v as? Double {
                return (k, d)
            }
            else if let i = v as? Int {
                return (k, Double(i))
            }
            return nil
            } as? [String : Double]
        
        return try Expression(expression, constants: constants).evaluate()
    }
    
    private func search(text: String, regexp: String) -> Int {
        if let range = text.range(of:regexp, options: .regularExpression) {
            return text.distance(from: text.startIndex, to: range.lowerBound)
        }
        
        return -1 //not found
    }
    
    private func searchUpperCase(text: String, regexp: String) -> Int {
        return search(text: text.uppercased(), regexp: regexp)
    }
    
    private func searchLowerCase(text: String, regexp: String) -> Int {
        return search(text: text.lowercased(), regexp: regexp)
    }
    
    private func substring(text: String, regexp: String) -> String {
        if let range = text.range(of:regexp, options: .regularExpression) {
            return text.substring(with:range)
        }
        
        return "" //not found
    }
    
    private func substringUpperCase(text: String, regexp: String) -> String {
        return substring(text: text.uppercased(), regexp: regexp)
    }
    
    private func substringLowerCase(text: String, regexp: String) -> String {
        return substring(text: text.lowercased(), regexp: regexp)
    }
    
    private func substring(text: String, from: Int, to: Int) -> String {
        
        return "" //TODO: implement and export as substringPos function in ExpressionFunction
    }
    
    private func substringUpperCase(text: String, from: Int, to: Int) -> String {
        return substring(text: text.uppercased(), from: from, to: to)
    }
    
    private func substringLowerCase(text: String, from: Int, to: Int) -> String {
        return substring(text: text.lowercased(), from: from, to: to)
    }
    
    private func getStringParameters(buffer: String) -> [String] {
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
            else if let variable = variables[parameter] as? String {
                parameter = variable
            }
            
            parameters[i] = parameter
        }
        
        return parameters
    }
    
    private func getExactNumberOfStringParameters(number: Int, buffer: String) throws -> [String] {
        let parameters = getStringParameters(buffer: buffer)
        
        guard parameters.count == number else {
            throw SwELError.wrongNumberParametersToFunction
        }
        
        return parameters
    }
    
    
    private func evaluateOperand(operand: String) throws -> Any {
        guard !operand.isEmpty else {
            throw SwELError.invalidOperand
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
                    throw SwELError.invalidOperand
                }
                
                return operand.replacingOccurrences(of: "'", with: "")
            }
            else if operand.hasPrefix("\"") {
                if !operand.hasSuffix("\"") {
                    throw SwELError.invalidOperand
                }
                
                return operand.replacingOccurrences(of: "\"", with: "")
            }
            else if let range = operand.range(of: "(") {
                if !operand.hasSuffix(")") {
                    throw SwELError.invalidOperand
                }
                
                let functionNameRange = Range<String.Index>(uncheckedBounds: (lower: operand.startIndex, upper: range.upperBound))
                let functionName = operand.substring(with:functionNameRange)
                
                let endIndex = operand.index(operand.endIndex, offsetBy: -2)
                let functionParameters = operand[range.upperBound...endIndex]
                
                if let function = ExpressionFunction(rawValue: functionName) {
                    switch function {
                    case .intFunction:
                        return try Int(calculateExpression(functionParameters))
                        
                    case .doubleFunction:
                        return try calculateExpression(functionParameters)
                        
                    case .searchFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return search(text: parameters[0], regexp: parameters[1])
                        
                    case .searchUpperFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return searchUpperCase(text: parameters[0], regexp: parameters[1])
                        
                    case .searchLowerFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return searchLowerCase(text: parameters[0], regexp: parameters[1])
                        
                    case .substringFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return substring(text: parameters[0], regexp: parameters[1])
                        
                    case .substringUpperFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return substringUpperCase(text: parameters[0], regexp: parameters[1])
                        
                    case .substringLowerFunction:
                        let parameters = try getExactNumberOfStringParameters(number: 2, buffer: functionParameters)
                        return substringLowerCase(text: parameters[0], regexp: parameters[1])
                    }
                }
                else {
                    throw SwELError.invalidFunction
                }
            }
            else {
                if let variable = variables[operand] {
                    return variable
                }
                throw SwELError.invalidOperand
            }
        }
    }
    
    private func evaluateCondition(left: String, op: ConditionOperator, right: String) throws -> Bool {
        let leftValue = try evaluateOperand(operand: left)
        let rightValue = try evaluateOperand(operand: right)
        
        guard type(of: leftValue) == type(of: rightValue) else {
            throw SwELError.differentOperandTypes
        }
        
        switch leftValue {
        case is Int:
            return compareInt(left: leftValue as! Int, right: rightValue as! Int, op: op)
            
        case is String:
            return compareString(left: leftValue as! String, right: rightValue as! String, op: op)
            
        case is Double:
            return compareDouble(left: leftValue as! Double, right: rightValue as! Double, op: op)
            
        default:
            throw SwELError.invalidOperandType
        }
    }
    
    private func evaluateCondition(condition: String) throws -> ConditionLogicOperator {
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
            throw SwELError.invalidCondition
        }
    }
}

