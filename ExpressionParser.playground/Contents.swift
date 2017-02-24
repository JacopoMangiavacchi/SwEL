//: ExpressionParser

import Foundation

enum ExpressionError : Error {
    case invalidSyntax
    case unclosedBracket
    case invalidOperator
    case invalidOperand
    case differentOperandTypes
    case unsupportedOperandType
}

enum ExpressionOperator : String {
    case equal = "=="
    case different = "!="
    case greater = ">"
    case greaterEqual = ">="
    case less = "<"
    case lessEqual = "<="
}

enum ExpressionBracket : String {
    case open = "("
    case close = ")"
}

enum ExpressionCondition : String {
    case and = "||"
    case or = "&&"
}

enum ExpressionStatus {
    case clear
    case inBracketExpression
    case inExpressionLeftOperand
    case inExpressionOperator
    case inExpressionRightOperand
}


extension String {
    func checkExpression(withVariables variables: [String : Any]? = nil) throws -> Bool {
        print("IN: \(self)")
        
        var previousExpression = true
        
        var status = ExpressionStatus.clear
        
        var innerExpression = ""
        var innerBracketCounter = 0
        var expLeftOperand = ""
        var expRightOperand = ""
        var expOperator = ""
        var validOperator:ExpressionOperator!
        
        func openBracket() {
            status = .inBracketExpression
            innerExpression = ""
            innerBracketCounter = 1
        }
        
        func closeBracket() {
            status = .clear
            innerExpression = ""
            innerBracketCounter = 0
        }
        
        func getLeftOperand() {
            status = .inExpressionLeftOperand
            expLeftOperand = ""
            expRightOperand = ""
            expOperator = ""
        }
        
        func getOperator() {
            status = .inExpressionOperator
            expOperator = ""
        }
        
        func getRightOperand() {
            status = .inExpressionRightOperand
            expRightOperand = ""
        }
        
        func closeExpression() {
            status = .clear
        }
        
        func getValidOperator(_ op: String) throws -> ExpressionOperator {
            func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
                var i = 0
                return AnyIterator {
                    let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
                    if next.hashValue != i { return nil }
                    i += 1
                    return next
                }
            }

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
        
        
        func evaluateOperand(operand: String) throws -> Any {
            guard operand.characters.count > 0 else {
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
                throw ExpressionError.unsupportedOperandType
            }
            
            
            return equal
        }
        
        
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
                if value == " " {
                    getOperator()
                }
                else {
                    expLeftOperand.append(value)
                }
                
            case .inExpressionOperator:
                if value == " " {
                    if expOperator.characters.count > 0 {
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
                if value == " "  || lastIndex {
                    if value != " " && lastIndex {
                        expRightOperand.append(value)
                    }
                    
                    if expRightOperand.characters.count > 0 {
                        closeExpression()
                        
                        previousExpression = try evaluateExpression(left: expLeftOperand, op: validOperator, right: expRightOperand)
                    }
                    else {
                        //nop
                    }
                }
                else {
                    expRightOperand.append(value)
                }
            }
            
        }
        
        if status != .clear {
            if status == .inBracketExpression {
                throw ExpressionError.unclosedBracket
            }
            
            throw ExpressionError.invalidSyntax
        }
        
        return previousExpression
    }
}


try! "  \"2\"   ==  '2s'  ".checkExpression()
try! " 1  ==  1 ".checkExpression()
try! " 1.2  ==  1.2 ".checkExpression()
try! " var1  ==  1 ".checkExpression(withVariables: ["var1" : 1])
try! " var1  ==  1.2 ".checkExpression(withVariables: ["var1" : 1.2])
try! " var1  ==  'test' ".checkExpression(withVariables: ["var1" : "test"])
try! " var1  ==  var2 ".checkExpression(withVariables: ["var1" : "test", "var2" : "test"])
try! " var1  ==  var2 ".checkExpression(withVariables: ["var1" : 1, "var2" : 1])
try! " var1  ==  var2 ".checkExpression(withVariables: ["var1" : 1.2, "var2" : 1.2])
try! " (var1  ==  var2) ".checkExpression(withVariables: ["var1" : 1.2, "var2" : 1.2])


//"(var1 == 1 && var2 == 2) || var2 == var3 || (var1 == var4 && (var4 == 1 && var2 == \"2\"))"



//TODO: ADD &&, ||
//TODO: ADD FUNCTION: upper, lower, substr, regex ...
//TODO: ADD ARITMETIC OPERATION +, -, *, /, %
//TODO: ADD BRACKET ON OPERAND




