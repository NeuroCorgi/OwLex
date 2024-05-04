import OwLex
import Regex

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

// _ = parseRegex(from: "casyy|t(q)a+")
// _ = parseRegex(from: "a*b*(c123)|(ab)*q+")
// _ = parseRegex(from: "a*b*(c123)|(ab)*q+")
_ = parseRegex(from: "a*b*(c123)")

// @Lexer
// private struct TokensDesc {
//     let `some` = /\d/
//     let other = /./

// }

// enum Token {
//     case `other` case some
// }
