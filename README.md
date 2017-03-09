[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Twitter](https://img.shields.io/badge/twitter-@jacopomangia-blue.svg?maxAge=2592000)](http://twitter.com/jacopomangia)


# SwEL (Swift Expression Language)

Do you need in your iOS, macOS, Linux projects to execute at runtime complex string based expression or condition evaluation like the string below ?

	"((var1 > var2 && var3 > int(max(var4, var5) * 1000)) || search(message, 'OK') >= 0) && errorCode != 400"

SwEL is a Swift String Extension and a Swift Struct exposing very simple API to evaluate String based Expressions and Conditions at runtime using two very simple methods:

1. evalExpression()  or  evalExpression(withVariables:)
2. checkCondition()  or  checkCondition(withVariables:)


# Introduction

SwEL (Swift Expression Language) is a Swift 3.x package for macOS, iOS and Linux for evaluating complex Conditions and Expressions at runtime from any Swift String.

Expression could be String RegEx based operations like for example "substring('this is a test', 'test|tost')" or mathematical expressions.

Mathematic Expressions could be based on simple arithmetic operations, like for example "int(3 + 4)", or on more complex mathematic operations using functions such as for example "float(2 * 3.14 + min(7, 13))".

Conditions could verify complex expression logic using AND/OR operator and infinite level of brackets like for example in the String "(1 == 2 || 2 < 4) && 'test' != 'ko'".

Both Expressions and Conditions can contain literals for constant String, Int, Float and Bool, as described in the previous examples, or dynamic bindings to variables passing a Dictionary of parameters value and referencing them for example in a String like "(var1 == var2 || var2 < var3) && var4 != 'ko'".


# How to install it?

SwEL is provided as as Swift 3.0 Package usable with Swift Package Manager on both macOS and Linux

In order to use it in your Swift project please include the following line in your Swift Package references:

	.Package(url: "https://github.com/JacopoMangiavacchi/SwEL", majorVersion: 0)


# Super easy String Extension usage

A SwEL Swift struct is provided with easy method to evaluate Expression and check Condition at runtime but this package also provide Swift String Extension to easily use all the SwEL functionalities


##Expression

It's super easy, you can call evalExpression() on any Swift String 

	try "substring('this is a test', 'test|tost')".evalExpression() //return "test"

	try "int(3 + 4)".evalExpression() //return 7

Or you can pass a Dictionary of parameters to bind directly to the expression like this

	try "substring(string, regex)".evalExpression(withVariables: [
		"string" : "this is a test",
		"regex" : "test|tost"
	])

	try "int(var1 + var2)".evalExpression(withVariables: [
		"var1" : 3,
		"var2" : 4
	])

The String extension evalExpression(), or evalExpression(withVariables:), will return a String, Bool, Int or Float value with the result of the evaluation if this is formally correct.  It will throws different exceptions according to different syntax error in the string value or variables dictionary.


##Expression Assignement

A special case of Expression are the one that will assing the result of an expression to an existing or new entry in the Variables Dictionary.

The following code for example execute the inner expression on left and assign it to the variable result on the Variables Dictionary

	let variables:[String : Any] = ["var1" : 2, "var2" : 3]
	try "result = int(var1 + var2)".evalExpression(withVariables: &variables) // return true
	//now variables["result"] == 5

In case of Expression Assignement the evalExpression(), or evalExpression(withVariables:), will return a True boolean value if the expression is formally correct.  It will throws different exceptions according to different syntax error in the string value or variables dictionary.


##Condition

It's super easy, you can call checkCondition() on any Swift String 

	try "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkCondition()

Or you can pass a Dictionary of parameters to bind directly to the condition like this

	try "(var1 == var2 || var2 < var3) && var4 != var5".checkCondition(withVariables: [
		"var1" : 1,
		"var2" : 2,
		"var3" : 4,
		"var4" : "test",
		"var5" : "ko"
	])

The String extension checkCondition(), or checkCondition(withVariables:), will return a Bool value with the result of the evaluation if this is formally correct.  It will throws different exceptions according to different syntax error in the string value or variables dictionary.


# String RegEx based expressions

The following string regex functions could be used on both left and right operand of any conditions

	search(string, regexp)  			// return -1 if not found
	searchUpper(string, regexp)  		// return -1 if not found
	searchLower(string, regexp)  		// return -1 if not found
	
	substring(string, regexp)  			// return "" if not found
	substringUpper(string, regexp)  	// return "" if not found
	substringLower(string, regexp)  	// return "" if not found

Here is an example of a complex condition evaluation containing complex expression with string functions:

	let text = "This is a test for testing regexp"
	let condition = "substring(\"\(text)\", regex) == result"
	try condition.checkCondition(withVariables: ["regex" : "test|tost",  "result" : "test"])


# Mathematic expressions

Mathematic expressions could be used on both left and right operand of any conditions using the following functions:

	int(expr)							// evaluate the math expr and return a Int value
	double(expr)						// evaluate the math expr and return a Double value

Inside the expressions passed to int() or double() functions more complex mathematic expressions could be used with the help of the following functions:

		sqrt(x)
		floor(x)
		ceil(x)
		round(x)
		cos(x)
		acos(x)
		sin(x)
		asin(x)
		tan(x)
		atan(x)
		abs(x)

		pow(x,y)
		max(x,y)
		min(x,y)
		atan2(x,y)
		mod(x,y)


For example this is a condition containing some basic arithmetic operations:

	let condition = "(var1 == 2.0 || double(var2) > double(var1 + 0.5))"

Here is an example of a complex condition evaluation containing complex expression with math and string functions and parameters in different format (Float, Int and String):

	let condition = "(var1 == 2.0 || double(var2) == double(var1 + min(0.5,3.5))) && 'test' != 'ko'"
	try condition.checkCondition(withVariables: ["var1" : 1.5, "var2" : 2, "var3" : "error"])


# SwEL struct usage for advanced use case

The SwEL Swift struct could be used instead of the provided String Extension in the following way

##Expression SwEL struct example

    let expression = "result = int(var1 + var2)"
    let variables:[String : Any] = ["var1" : 2, "var2" : 3]

    let exp = SwEL(expression, variables: variables)
    try exp.evalExpression() // return true and insert ("result" : 5) in the SwEL.variables Dictionary properties
    
	//now exp.variables["result"] == 5

##Condition SwEL struct example

	let exp = SwEL("search(string, regexp) >= 0", 
	               variables: [
					   "string" : "jacopo@me.com", 
					   "regexp" : "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
					])

    try exp.checkCondition()


# Contributing to SwEL

All improvements are very welcome!

1. Clone this repository.

		`$ git clone https://github.com/JacopoMangiavacchi/SwEL`

2. Build and run tests.

		`$ swift test`

# Reference to Open Source library used

For evaluating mathematic expressions this Package use the Expression library provided by Nick Lockwood and available at https://github.com/nicklockwood/Expression
