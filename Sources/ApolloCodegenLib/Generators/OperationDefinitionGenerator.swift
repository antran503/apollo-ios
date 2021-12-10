import ApolloAPI

struct Template: ExpressibleByStringInterpolation, CustomStringConvertible {

  let value: String

  init(stringLiteral: String) {
    self.value = stringLiteral
  }

  init(stringInterpolation: StringInterpolation) {
    self.value = stringInterpolation.output
  }

  var description: String { value }

  struct StringInterpolation: StringInterpolationProtocol {
    var output: String

    init(literalCapacity: Int, interpolationCount: Int) {
      var string = String()
      string.reserveCapacity(literalCapacity)
      self.output = string
    }

    mutating func appendLiteral(_ literal: StringLiteralType) {
      output.append(literal)
    }

    mutating func appendInterpolation(_ template: Template) {
      appendInterpolation(template.value)
    }

    mutating func appendInterpolation(_ string: String) {
      let indent = output.reversed().prefix { " \t".contains($0) }
      if indent.isEmpty {
        appendLiteral(string)
      } else {
        let indentedString = string
          .split(separator: "\n", omittingEmptySubsequences: false)
          .joined(separator: "\n" + indent)

        appendLiteral(indentedString)
      }
    }

    mutating func appendInterpolation(if bool: Bool, _ string: String) {
      if bool {
        appendInterpolation(string)
      } else {
        removeLineIfEmpty()
      }
    }

    mutating func appendInterpolation(if bool: Bool, _ template: Template) {
      appendInterpolation(if: bool, template.value)
    }

    private mutating func removeLineIfEmpty() {
      let slice = substringToStartOfLine()
      if !slice.isEmpty && slice.allSatisfy(\.isWhitespace) {
        output.removeLast(slice.count + 1) // + 1 removes the \n character.
      }
    }

    private func substringToStartOfLine() -> Slice<ReversedCollection<String>> {
      return output.reversed().prefix { !$0.isNewline }
    }
  }
}

//protocol ContextComponent {
//  func toContextDictionary() -> String
//}

//extension CompiliationResult.OperationDefinition: ContextComponent {
//  func toContextDictionary() -> String {
//    ["source": ]
//  }
//}

enum OperationDefinitionGenerator {

//  static let templates = [
//    "documentType": DocumentType.template
//  ]
//  static let environment = Environment(loader: DictionaryLoader(templates: templates))
//
//  static func render(
//    operation: CompilationResult.OperationDefinition,
//    in schema: IR.Schema,
//    config: ApolloCodegenConfiguration
//  ) throws -> String {
//    let context: [String: Any] = [
//      "schema": schema,
//      "operation": operation,
//      "config": config
//    ]
//    return try environment.renderTemplate(string: template, context: context)
//  }
//
//  private static let template =
//  """
//  query \(operation.name) {
//    \(indented: OperationDefinition.DocumentType.render(operation: operation)
//  }
//  """

}

extension OperationDefinitionGenerator {
  enum DocumentType {

    static func render(
      operation: CompilationResult.OperationDefinition,
      apq: ApolloCodegenConfiguration.APQConfig
    ) -> Template {
      """
      public let document: DocumentType = .notPersisted(
        \(if: apq != .disabled,
        "operationIdentifier: \(operation.operationIdentifier),"
        )
        definition: .init(
        ""\"
        \(operation.source)
        ""\"))
      """
    }

  }
}

extension ApolloCodegenConfiguration.APQConfig {

}
