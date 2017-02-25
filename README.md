[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
[![Twitter](https://img.shields.io/badge/twitter-@jacopomangia-blue.svg?maxAge=2592000)](http://twitter.com/jacopomangia)


## What is Swift-Expression-Parser

ExpressionParser is a Swift 3.x String extension for macOS, iOS and linux for evaluating complex expressions with AND/OR conditions and Dynamic bindings to parameters from any String at runtime.


## How to install it?

ExpressionParser is provided as as Swift 3.0 Package usable with Swift Package Manager on both macOS and linux

In order to usit in your Swift project please include the following line in your Swift Package references:

	.Package(url: "https://github.com/JacopoMangiavacchi/Swift-Expression-Parser", majorVersion: 0)

## How to use it?

It's super easy, you can call checkExpression() on any Swift String 

	try! "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkExpression()

Or you can pass a Dictionary of parameters to bind directly to the expression like this

	try! "(var1 == var2 || var2 < var3) && var4 != var5".checkExpression(withVariables: [
		"var1" : 1,
		"var2" : 2,
		"var3" : 4,
		"var4" : "test",
		"var5" : "ko"
	])

The String extension checkExpression(), or checkExpression(withVariables:), will return a Bool value with the result of the evaluation if this is formally correct.  It will throws different exceptions according to diffferent syntax error in the string value or variables dictionary.


## Evaluating numeric expressions inside the AND/OR expression conditions

**Warning: This is work in progress**






## Contributing to Swift-Expression-Parser

All improvements are very welcome!

1. Clone this repository.

  `$ git clone https://github.com/JacopoMangiavacchi/Swift-Expression-Parser`

2. Build and run tests.

  `$ swift test`


## Reference to Open Source library used

For evaluating numeric expressions inside the AND/OR expression conditions this Package use the Expression library provided by Nick Lockwood and available at https://github.com/nicklockwood/Expression




