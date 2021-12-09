import Stencil

class OperationDefinitionExtension: Extension {
  override init() {
    super.init()

    registerSimpleTag("documentType") { context in
      """
      public let
      """
    }
  }
}

//extension CompilationResult.OperationDefinition: ContextComponent {
//  let contextKey: String { "operation" }
//}
//
//protocol ContextComponent {
//  var contextKey: String { get }
//}
//
//extension ContextComponent {
//  func toContextDictionary() -> [String: Any] {
//    [Self.contextKey: self]
//  }
//}
//
//extension Environment {
//  func renderTemplate(string: String, context: [ContextComponent]) throws -> String {
//    let context = Dictionary(uniqueKeysWithValues: context.map { ($0.contextKey, )})
//  }
//}
//
//extension Context {
//  func push<Result>(
//    _ contextComponent: ContextComponent,
//    closure: (() throws -> Result)
//  ) rethrows -> Result {
//    try push(dictionary: contextComponent.toContextDictionary(), closure: closure)
//  }
//}

//extension Context {
//  enum Keys {
//    static let Schema = "schema"
//  }
//
//
//  var schema: Schema {
//    get { self[Keys.Schema] as! Schema }
//    set { self[Keys.Schema] = newValue }
//  }

//  func render(_ templateString: Template) throws -> String {
////    environment.r
//  }
//
//}


enum OperationDefinitionGenerator {

  static func render(
    operation: CompilationResult.OperationDefinition,
    in schema: IR.Schema,
    config: ApolloCodegenConfiguration
  ) throws -> String {
    let context: [String: Any] = [
      "schema": schema,
      "operation": operation,
      "config": config
    ]
    return try template.render(context)
  }

  private static let template: Template = """
  query {{ operation.name }}
  """

}
