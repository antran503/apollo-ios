import Foundation
import OrderedCollections

extension IR {
  class Operation {
    let definition: CompilationResult.OperationDefinition

    /// The root field of the operation. This field must be the root query, mutation, or
    /// subscription field of the schema.
    let rootField: EntityField

    /// All fragments referenced by all selections sets in the operation.
    let fragmentsUsed: OrderedSet<CompilationResult.FragmentDefinition>

    lazy var operationIdentifier: String = {
      #warning("TODO: Compute this from source + referenced fragments")
      return ""
    }()

    init(
      definition: CompilationResult.OperationDefinition,
      rootField: EntityField,
      fragmentsUsed: OrderedSet<CompilationResult.FragmentDefinition>
    ) {
      self.definition = definition
      self.rootField = rootField
      self.fragmentsUsed = fragmentsUsed
    }
  }
}
