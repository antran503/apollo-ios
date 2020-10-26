import Foundation
import Stencil

public class FragmentGenerator {
  public struct SanitizedFragment {
    /// The name of the fragment.
    let name: String
    
    /// The primary type the fragment is defined on
    let typeCondition: String
    
    /// All possible types that fragment could represent, if for instance the primary type is a Union or an Interface.
    let possibleTypes: [String]
    
    let fields: [ASTField]
    
    /// The variable declaration of the fragment
    let nameVariableDeclaration: String
  
    /// The variable usage of the fragment
    let nameVariableUsage: String
    
    /// The raw source of the fragment
    let source: String
    
    init(from fragment: ASTFragment) {
      if fragment.fragmentName == fragment.typeCondition {
        // We need to distinguish between the two types
        self.name = "\(fragment.fragmentName)Fragment"
      } else {
        self.name = fragment.fragmentName
      }
      
      self.nameVariableDeclaration = self.name.apollo.sanitizedVariableDeclaration
      self.nameVariableUsage = self.name.apollo.sanitizedVariableUsage
      self.fields = fragment.fields
      self.source = fragment.source
      self.typeCondition = fragment.typeCondition
      self.possibleTypes = fragment.possibleTypes
    }
  }
  
  public enum FragmentContextKey: String {
    case fragment
    case renderedFields
    case renderedSource
    case modifier
  }
  
  /// Designated initializer
  public init() { }
  
  func run(fragment: ASTFragment, options: ApolloCodegenOptions) throws -> String {
    let sanitized = SanitizedFragment(from: fragment)
    
    let fieldGenerator = FieldGenerator()
    let renderedFields = try sanitized.fields.map {
      try fieldGenerator.run(field: $0,
                             accessor: .mutable,
                             fragmentMode: .getterOnly,
                             parentFragment: fragment,
                             options: options)
    }
    
    let context: [FragmentContextKey: Any] = [
      .fragment: sanitized,
      .renderedSource: fragment.source,
      .renderedFields: renderedFields,
      .modifier: options.modifier.prefixValue
    ]
    
    return try Environment().renderTemplate(string: self.fragmentTemplate,
                                            context: context.apollo.toStringKeyedDict)
  }
  
  /// A stencil template to use to render interface enums.
  ///
  /// Variable to allow custom modifications, but MODIFY AT YOUR OWN RISK.
  open var fragmentTemplate: String {
    ##"""
{{ modifier }}protocol {{ fragment.name }}: GraphQLFragment, Codable {
{% for field in renderedFields %}{{ field | indent:2, " ", true }}{% if not forloop.last %}
{% endif %}{% endfor %}
}

// MARK: - Default implementation

{{ modifier }}extension {{ fragment.name }} {
  static var fragmentDefinition: String {
#"""
{{ renderedSource }}
"""#
  }
}
"""##
  }
}
