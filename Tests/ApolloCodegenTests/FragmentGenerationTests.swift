//
//  FragmentGenerationTests.swift
//  ApolloCodegenTests
//
//  Created by Ellen Shapiro on 10/20/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import XCTest
@testable import ApolloCodegenLib

class FragmentGenerationTests: XCTestCase {
  
  func testGeneratingFragmentWithInterfaceTypeForTypename() throws {
    let typenameField = ASTField(responseName: "__typename",
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
    let nameField = ASTField(responseName: "name",
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
    
    
    let fragment = ASTFragment(typeCondition: "Character",
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
    
    do {
      let generator = FragmentGenerator()
      let output = try generator.run(fragment: fragment,
                                     options: CodegenTestHelper.dummyOptions())

      let expectedFileURL = CodegenTestHelper.sourceRootURL()
        .appendingPathComponent("Tests")
        .appendingPathComponent("ApolloCodegenTests")
        .appendingPathComponent("ExpectedCharacterNameAndAppearsInFragment.swift")

      LineByLineComparison.between(received: output,
                                   expectedFileURL: expectedFileURL,
                                   trimImports: true)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
    }
  }
  
  func testGeneratingFragmentWithImplementerOfInterfaceTypeAsTypeCondition() {
    let typenameField = ASTField(responseName: "__typename",
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
    let nameField = ASTField(responseName: "name",
                             fieldName: "name",
                             typeNode: .nonNullNamed("String"),
                             isConditional: false,
                             conditions: nil,
                             description: "What others call this droid",
                             isDeprecated: nil,
                             args: nil,
                             fields: nil,
                             fragmentSpreads: nil,
                             inlineFragments: nil)
    let primaryFunctionField = ASTField(responseName: "primaryFunction",
                                        fieldName: "primaryFunction",
                                        typeNode: .nonNullNamed("String"),
                                        isConditional: false,
                                        conditions: nil,
                                        description: "This droid's primary function",
                                        isDeprecated: nil,
                                        args: nil,
                                        fields: nil,
                                        fragmentSpreads: nil,
                                        inlineFragments: nil)
    
    let fragment = ASTFragment(typeCondition: "Droid",
                               possibleTypes: [
                                 "Droid"
                               ],
                               fragmentName: "DroidDetails",
                               filePath: "",
                               source: "fragment DroidDetails on Droid {\n  __typename\n  name\n  primaryFunction\n}",
                               fields: [
                                typenameField,
                                nameField,
                                primaryFunctionField,
                               ],
                               fragmentSpreads: [],
                               inlineFragments: [])
    
    do {
      let generator = FragmentGenerator()
      let output = try generator.run(fragment: fragment,
                                     options: CodegenTestHelper.dummyOptions())

      let expectedFileURL = CodegenTestHelper.sourceRootURL()
        .appendingPathComponent("Tests")
        .appendingPathComponent("ApolloCodegenTests")
        .appendingPathComponent("ExpectedDroidDetailsFragment.swift")

      LineByLineComparison.between(received: output,
                                   expectedFileURL: expectedFileURL,
                                   trimImports: true)
    } catch {
      CodegenTestHelper.handleFileLoadError(error)
    }
  }
}
