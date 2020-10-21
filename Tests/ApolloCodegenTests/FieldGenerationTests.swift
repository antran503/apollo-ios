//
//  FieldGenerationTests.swift
//  ApolloCodegenTests
//
//  Created by Ellen Shapiro on 10/20/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import XCTest
@testable import ApolloCodegenLib

class FieldGenerationTests: XCTestCase {
  
  func testGeneratingNonNullArrayOfNonNullObjectsForFragment() throws {
    let appearsInField = ASTField(responseName: "appearsIn",
                                  fieldName: "appearsIn",
                                  typeNode: .nonNullList(of: .nonNullNamed("Episode")),
                                  isConditional: false,
                                  conditions: nil,
                                  description: "The movies this character appears in",
                                  isDeprecated: nil,
                                  args: nil,
                                  fields: nil,
                                  fragmentSpreads: nil,
                                  inlineFragments: nil)
    
    let generator = FieldGenerator()
    let output = try generator.run(field: appearsInField,
                                   accessor: .mutable,
                                   fragmentMode: .getterOnly,
                                   options: CodegenTestHelper.dummyOptions())
    
    XCTAssertEqual("var appearsIn: [Episode] { get }", output)
    
  }
}
