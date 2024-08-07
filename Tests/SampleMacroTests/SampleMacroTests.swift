import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SampleMacroMacros)
import SampleMacroMacros

let testMacros: [String: Macro.Type] = [
    "EnumSubset": SlopeSubsetMacro.self
]
#endif

final class SampleMacroTests: XCTestCase {
    func testSlopeSubset() {
        assertMacroExpansion(
        """
        @EnumSubset<Slope>
        enum EasySlope {
            case beginnersParadise
            case practiceRun
        }
        """
        , expandedSource:
            """
            enum EasySlope {
                case beginnersParadise
                case practiceRun
            
                init?(_ slope: Slope) {
                    switch slope {
                    case .beginnersParadise:
                        self = .beginnersParadise
                    case .practiceRun:
                        self = .practiceRun
                    default:
                        return nil
                    }
                }
            }
            """, macros: testMacros)
    }
    
    func testSlopeSubsetOnStruct() throws {
        assertMacroExpansion(
            """
            @EnumSubset
            struct Skier {
            }
            """
            , expandedSource:
            """
            struct Skier {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@EnumSubsetはenumにだけ使えます", line: 1, column: 1)
            ],
            macros: testMacros)
    }
}


