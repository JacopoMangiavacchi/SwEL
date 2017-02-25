import XCTest
@testable import ExpressionParser

class ExpressionParserTests: XCTestCase {
    func testExample1() {
        XCTAssertEqual(try "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkExpression(), true)
    }

    func testExample2() {
        XCTAssertEqual(try "(var1 == var2 || var2 < var3) && var4 != var5".checkExpression(withVariables: [
            "var1" : 1,
            "var2" : 2,
            "var3" : 4,
            "var4" : "test",
            "var5" : "ko"
            ]), true)
    }

    static var allTests : [(String, (ExpressionParserTests) -> () throws -> Void)] {
        return [
            ("testExample1", testExample1),
            ("testExample2", testExample2)
        ]
    }
}
