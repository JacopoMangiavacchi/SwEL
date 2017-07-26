//let condition = "(var1 == 2.0 || Double(var2) > Double(var1 + 0.5)) && 'test' != 'ko'"
let condition = "(var1 == 2.0 || Double(var2) == Double(var1 + min(0.5,3.5))) && 'test' != 'ko'"

print(condition)

do {
    if try condition.checkCondition(withVariables: ["var1" : 1.5, "var2" : 2, "var3" : "error"]) {
        print("True")
    }
    else {
        print("False")
    }
}
catch let error {
    print(error)
}


