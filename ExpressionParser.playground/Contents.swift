//: ExpressionParser

import Foundation

enum ExpressionError : Error {
    case invalidSyntax
    case unclosedBracket
    case invalidOperator
    case invalidLeftOperand
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
    func checkExpressionWithVariables(_ variables: [String : Any]) throws -> Bool {
        print("IN: \(self)")
        
        var resultExpression = ""
        
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
        
        
        func evaluateExpression(left: String, op: ExpressionOperator, right: String) throws -> Bool {
            guard let leftValue = variables[left] else {
                throw ExpressionError.invalidLeftOperand
            }
            
            //TODO: Check rules for right format
            // - begin with Number it meens that it's a Int or Double value
            // - begin with " or ' it meens that it's a String value
            // - else is a key for variables as left (if not found exception invalidRightOperand
            
            
            
            let rightValue:Any = variables[right] ?? right.replacingOccurrences(of: "\"", with: "")
            
            if type(of: leftValue) != type(of: rightValue) {
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
                        resultExpression.append(try innerExpression.checkExpressionWithVariables(variables) ? "1" : "0")
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
                    if lastIndex {
                        expRightOperand.append(value)
                    }
                    
                    if expRightOperand.characters.count > 0 {
                        closeExpression()
                        
                        resultExpression.append(try evaluateExpression(left: expLeftOperand, op: validOperator, right: expRightOperand) ? "1" : "0")
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
        
        print("OUT: \(resultExpression)")
        
        //TODO: Evaluate resultExpression and return true or false
        
        return false
    }
}




let variables:[String : Any] = ["var1" : 1, //1,  //1.3  //"1"
                                "var2" : "2",
                                "var3" : 2,
                                "var4" : 1]

//let expression = "  var1   ==  \"pippo\""
//let expression = "  var1   ==   1 "
let expression = "  var2   ==  2  "

//let expression = "(var1 == 1 && var2 == 2) || var2 == var3 || (var1 == var4 && (var4 == 1 && var2 == \"2\"))"


try! expression.checkExpressionWithVariables(variables)

