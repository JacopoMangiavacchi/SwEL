import XCTest
@testable import SwEL

class ConditionParserTests: XCTestCase {
    func testExample1() {
        let condition = "(1 == 2 || 2 < 4) && 'test' != 'ko'"
        let exp = SwEL(condition)

        XCTAssertEqual(try exp.checkCondition(), true)
    }

    func testExample2() {
        XCTAssertEqual(try "(1 == 2 || 2 < 4) && 'test' != 'ko'".checkCondition(), true)
    }

    func testExample3() {
         XCTAssertEqual(try "(var1 == var2 || var2 < var3) && var4 != var5".checkCondition(withVariables: [
             "var1" : 1,
             "var2" : 2,
             "var3" : 4,
             "var4" : "test",
             "var5" : "ko"
             ]), true)
    }

    static var allTests : [(String, (ConditionParserTests) -> () throws -> Void)] {
        return [
            ("testExample1", testExample1),
            ("testExample2", testExample2),
            ("testExample3", testExample3)
        ]
    }
}
