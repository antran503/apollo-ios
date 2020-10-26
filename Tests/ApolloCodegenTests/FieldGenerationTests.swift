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
  
  var typenameField: ASTField {
    ASTField(responseName: "__typename",
                                 fieldName: "__typename",
                                 typeNode: .nonNullNamed("String"),
                                 isConditional: false,
                                 conditions: nil,
                                 description: nil,
                                 isDeprecated: nil,
                                 args: nil,
                                 fields: nil,
                                 fragmentSpreads: nil,
                                 inlineFragments: nil)
  }
  
  var nameField: ASTField {
    ASTField(responseName: "name",
                             fieldName: "name",
                             typeNode: .nonNullNamed("String"),
                             isConditional: false,
                             conditions: nil,
                             description: "The name of the character",
                             isDeprecated: nil,
                             args: nil,
                             fields: nil,
                             fragmentSpreads: nil,
                             inlineFragments: nil)
  }
  
  var appearsInField: ASTField {
    ASTField(responseName: "appearsIn",
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
  }
  
  var characterNameAndAppearsInFragment: ASTFragment {
    ASTFragment(typeCondition: "Character",
                possibleTypes: [
                  "Human",
                  "Droid"
                ],
                fragmentName: "CharacterNameAndAppearsIn",
                filePath: "",
                source: "fragment CharacterNameAndAppearsIn on Character {\n  __typename\n  name\n  appearsIn\n}",
                fields: [
                  typenameField,
                  nameField,
                  appearsInField,
                ],
                fragmentSpreads: [],
                inlineFragments: [])
  }
  
  func testGeneratingNonNullArrayOfNonNullObjectsForFragment() throws {
    let generator = FieldGenerator()
    let output = try generator.run(field: appearsInField,
                                   accessor: .mutable,
                                   fragmentMode: .getterOnly,
                                   parentFragment: characterNameAndAppearsInFragment,
                                   options: CodegenTestHelper.dummyOptions())
    
    XCTAssertEqual(
"""
/// The movies this character appears in
var appearsIn: [Episode] { get }
""", output)
  }
  
  
  func testGeneratingNonNullTypeForFragment() throws {
    let generator = FieldGenerator()
    let output = try generator.run(field: nameField,
                                   accessor: .mutable,
                                   fragmentMode: .getterOnly,
                                   parentFragment: characterNameAndAppearsInFragment,
                                   options: CodegenTestHelper.dummyOptions())
    
    XCTAssertEqual(
"""
/// The name of the character
var name: String { get }
""", output)
  }
  
  func testGeneratingUnionTypeForFragment() throws {
    let generator = FieldGenerator()
    let output = try generator.run(field: typenameField,
                                   accessor: .mutable,
                                   fragmentMode: .getterOnly,
                                   parentFragment: characterNameAndAppearsInFragment,
                                   options: CodegenTestHelper.dummyOptions())
    
    XCTAssertEqual(
"""
var __typename: CharacterType { get }
""", output)
  }
}
