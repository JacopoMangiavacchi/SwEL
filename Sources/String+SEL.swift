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
        let exp = SwiftExpressionLanguage(self, variables: variables)
        
        return try exp.checkCondition()
    }
}
