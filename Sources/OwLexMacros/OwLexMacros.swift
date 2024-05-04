import SwiftCompilerPlugin
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

enum LexerError: Error, CustomStringConvertible {
    case argError
    case typeError
    case declError

    case patternError
    case nameError
    case initError

    var description: String {
        return
          switch self {
          case .argError:
              "Lexer macro does not take any arguments"
          case .typeError:
              "Lexer decription must be a 'struct'"
          case .declError:
              "Unexpected declaration"
          case .patternError:
              "Lexeme must be a single pattern"
          case .nameError:
              "Lexeme name must be an identifier"
          case .initError:
              "Lexeme must have an initializer of a literal regex"
        }
    }
}


struct Lexeme {
    let name: TokenSyntax
    let regex: String

    init?(
      from decl: VariableDeclSyntax,
      in context: some MacroExpansionContext)
    {
        guard let bind = decl.bindings.first,
              decl.bindings.count == 1
        else {
            context.addDiagnostics(from: LexerError.patternError, node: decl.bindings)
            return nil
        }

        guard let id = bind.pattern.as(IdentifierPatternSyntax.self)
        else {
            context.addDiagnostics(
              from: LexerError.nameError,
              node: bind.pattern
            )
            return nil
        }

        guard let initializer = bind.initializer?.value,
              let regex = initializer.as(RegexLiteralExprSyntax.self)
        else {
            context.addDiagnostics(from: LexerError.initError, node: bind)
            return nil
        }

        self.name = id.identifier
        self.regex = regex.regex.text
    }

}

func hasPrivate(in modifiers: DeclModifierListSyntax) -> Bool {
    return nil != modifiers
      .first(where: { $0.name.tokenKind == .keyword(.private) })
}

public struct LexerMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        if let _ = node.arguments {
            throw LexerError.argError
        }

        guard let lexerDescription = declaration.as(StructDeclSyntax.self) else {
            throw LexerError.typeError
        }

        if !hasPrivate(in: lexerDescription.modifiers) {
            // Provide warning
        }

        var patterns: [Lexeme] = []
        var skipped: [Lexeme] = []

        for decl in lexerDescription.memberBlock.members.map({ $0.decl }) {
            guard let varDecl = decl.as(VariableDeclSyntax.self) else {
                let messageID = MessageID(domain: "OwLex", id: "UnknownDecl")
                // let diag = Diagnostic(
                //   node: Syntax(decl),
                //   message: SimpleDiagnosticMessage()
                // )
                context.addDiagnostics(from: LexerError.declError, node: decl)
                continue
            }

            guard let lexeme = Lexeme(from: varDecl, in: context) else {
                continue
            }
            
            if hasPrivate(in: varDecl.modifiers) {
                skipped.append(lexeme)
            } else {
                patterns.append(lexeme)
            }
        }

        // let t = EnumDeclSyntax(e
        let tokenEnum = try EnumDeclSyntax("enum Token") {
            for name in patterns.map({ $0.name }) {
                EnumCaseDeclSyntax {
                    EnumCaseElementListSyntax {
                        EnumCaseElementSyntax(name: name)
                    }
                }
            }
        }

        print("=====================")
        print("ENUM PRODUCED:")
        print(tokenEnum)
        print("=====================")

        return [DeclSyntax(tokenEnum)]
        // return []
    }
}


@main
struct OwLexPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [      
      StringifyMacro.self,
      LexerMacro.self,
    ]
}
