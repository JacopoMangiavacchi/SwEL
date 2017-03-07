//  SwEL (Swift Expression Language)
//
//  String+SwEL.swift
//
//  Version 0.3
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
        let exp = SwEL(self, variables: variables)
        
        return try exp.checkCondition()
    }
}
