[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Twitter](https://img.shields.io/badge/twitter-@jacopomangia-blue.svg?maxAge=2592000)](http://twitter.com/jacopomangia)


## SwEL (Swift Expression Language)

SwEL (Swift Expression Language) is a Swift 3.x package for macOS, iOS and linux for evaluating complex conditions with AND/OR, infinite level of brackets and dynamic bindings to parameters from any String at runtime.


## How to install it?

SwEL is provided as as Swift 3.0 Package usable with Swift Package Manager on both macOS and linux

In order to usit in your Swift project please include the following line in your Swift Package references:

	.Package(url: "https://github.com/JacopoMangiavacchi/SwEL", majorVersion: 0)

## Super easy String Extension usage

A SwEL Swift class is provided with easy method to evaluate condition at runtime but this package also provide Swift String Extension to easily

It's super easy, you can call checkCondition() on any Swift String 

	try! "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkCondition()

Or you can pass a Dictionary of parameters to bind directly to the condition like this

	try! "(var1 == var2 || var2 < var3) && var4 != var5".checkCondition(withVariables: [
		"var1" : 1,
		"var2" : 2,
		"var3" : 4,
		"var4" : "test",
		"var5" : "ko"
	])

The String extension checkCondition(), or checkCondition(withVariables:), will return a Bool value with the result of the evaluation if this is formally correct.  It will throws different exceptions according to diffferent syntax error in the string value or variables dictionary.

## Evaluating String expressions with RegExp inside the AND/OR conditions
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
	try! condition.checkCondition(withVariables: ["regex" : "test|tost",  "result" : "test"])


## Evaluating mathematic expressions inside the AND/OR conditions

Mathematic expressions could be used on both left and right operand of any conditions using the following functions:

	int(expr)							// evaluate the math expr and return a Int value
	double(expr)						// evaluate the math expr and return a Double value

For example this is a condition containing some basic arithmetic operations:

	let condition = "(var1 == 2.0 || double(var2) > double(var1 + 0.5)) && 'test' != 'ko'"

Inside the expr passed to int() or double() functions more complex mathematic expressions could be used with the help of the following functions:

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

Here is an example of a complex condition evaluation containing complex expression with math functions:

	let condition = "(var1 == 2.0 || Double(var2) == double(var1 + min(0.5,3.5))) && 'test' != 'ko'"
	try! condition.checkCondition(withVariables: ["var1" : 1.5, "var2" : 2, "var3" : "error"])


## SwEL usage for advanced use case
The SwEL Swift class could be used instead of the provided String Extension in the following way

	let exp = SwEL("search(string, regexp) >= 0", 
	               variables: [
					   "string" : "jacopo@me.com", 
					   "regexp" : "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
					])
    try exp.checkCondition()


## Contributing to SwEL

All improvements are very welcome!

1. Clone this repository.

  `$ git clone https://github.com/JacopoMangiavacchi/SwEL`

2. Build and run tests.

  `$ swift test`


## Reference to Open Source library used

For evaluating mathematic expressions inside the AND/OR conditions this Package use the Expression library provided by Nick Lockwood and available at https://github.com/nicklockwood/Expression




