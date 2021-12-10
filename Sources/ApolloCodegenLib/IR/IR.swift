import OrderedCollections
import ApolloUtils

class IR {

  let schema: Schema
  let compilationResult: CompilationResult

  init(schemaName: String, compilationResult: CompilationResult) {
    self.schema = Schema(name: schemaName, compilationResult: compilationResult)
    self.compilationResult = compilationResult
  }

  struct Schema {
    let name: String
    let referencedTypes: ReferencedTypes

    init(name: String, compilationResult: CompilationResult) {
      self.name = name
      self.referencedTypes = ReferencedTypes(compilationResult.referencedTypes)
    }

    public final class ReferencedTypes {
      let allTypes: Set<GraphQLNamedType>

      let objects: Set<GraphQLObjectType>
      let interfaces: Set<GraphQLInterfaceType>
      let unions: Set<GraphQLUnionType>
      let scalars: Set<GraphQLScalarType>
      let enums: Set<GraphQLEnumType>
      let inputObjects: Set<GraphQLInputObjectType>

      init(_ types: [GraphQLNamedType]) {
        self.allTypes = Set(types)

        var objects = Set<GraphQLObjectType>()
        var interfaces = Set<GraphQLInterfaceType>()
        var unions = Set<GraphQLUnionType>()
        var scalars = Set<GraphQLScalarType>()
        var enums = Set<GraphQLEnumType>()
        var inputObjects = Set<GraphQLInputObjectType>()

        for type in allTypes {
          switch type {
          case let type as GraphQLObjectType: objects.insert(type)
          case let type as GraphQLInterfaceType: interfaces.insert(type)
          case let type as GraphQLUnionType: unions.insert(type)
          case let type as GraphQLScalarType: scalars.insert(type)
          case let type as GraphQLEnumType: enums.insert(type)
          case let type as GraphQLInputObjectType: inputObjects.insert(type)
          default: continue
          }
        }

        self.objects = objects
        self.interfaces = interfaces
        self.unions = unions
        self.scalars = scalars
        self.enums = enums
        self.inputObjects = inputObjects
      }

      private var typeToUnionMap: [GraphQLObjectType: Set<GraphQLUnionType>] = [:]

      public func unions(including type: GraphQLObjectType) -> Set<GraphQLUnionType> {
        if let unions = typeToUnionMap[type] {
          return unions
        }

        let matchingUnions = unions.filter { $0.types.contains(type) }
        typeToUnionMap[type] = matchingUnions
        return matchingUnions
      }
    }
  }  

  /// Represents a concrete entity in an operation that fields are selected upon.
  ///
  /// Multiple `SelectionSet`s may select fields on the same `Entity`. All `SelectionSet`s that will
  /// be selected on the same object share the same `Entity`.
  class Entity: Equatable {
    /// The selections that are selected for the entity across all type scopes in the operation.
    /// Represented as a tree.
    let mergedSelectionTree: MergedSelectionTree

    /// A list of path components indicating the path to the field containing the `Entity` in
    /// an operation.
    let fieldPath: ResponsePath

    var rootTypePath: LinkedList<GraphQLCompositeType> { mergedSelectionTree.rootTypePath }

    var rootType: GraphQLCompositeType { rootTypePath.last.value }

    init(
      rootTypePath: LinkedList<GraphQLCompositeType>,
      fieldPath: ResponsePath
    ) {
      self.mergedSelectionTree = MergedSelectionTree(rootTypePath: rootTypePath)
      self.fieldPath = fieldPath
    }

    static func == (lhs: IR.Entity, rhs: IR.Entity) -> Bool {
      lhs.mergedSelectionTree === rhs.mergedSelectionTree
    }
  }

  class SelectionSet: Equatable {
    /// The entity that the `selections` are being selected on.
    ///
    /// Multiple `SelectionSet`s may reference the same `Entity`
    let entity: Entity

    let parentType: GraphQLCompositeType

    /// A list of the type scopes for the selection set and its enclosing entities.
    ///
    /// The selection set's type scope is the last element in the list.
    let typePath: LinkedList<TypeScopeDescriptor>

    /// Describes all of the types the selection set matches.
    /// Derived from all the selection set's parents.
    var typeScope: TypeScopeDescriptor { typePath.last.value }

    /// The selections that are directly selected by this selection set.
    var selections: SortedSelections = SortedSelections()

    /// The selections that will be selected for this selection set.
    ///
    /// Includes the direct selections, along with all selections from other related
    /// `SelectionSet`s on the same entity that match the selection set's type scope.
    ///
    /// Selections in the `mergedSelections` are guarunteed to be selected if this `SelectionSet`'s
    /// `selections` are selected. This means they can be merged into the generated object
    /// representing this `SelectionSet` as field accessors.
    lazy var mergedSelections: SortedSelections = entity.mergedSelectionTree
      .mergedSelections(forSelectionSet: self)

    init(
      entity: Entity,
      parentType: GraphQLCompositeType,
      typePath: LinkedList<TypeScopeDescriptor>
    ) {
      self.entity = entity
      self.parentType = parentType
      self.typePath = typePath
    }

    static func == (lhs: IR.SelectionSet, rhs: IR.SelectionSet) -> Bool {
      lhs.entity == rhs.entity &&
      lhs.parentType == rhs.parentType &&
      lhs.typePath == rhs.typePath &&
      lhs.selections == rhs.selections
    }
  }

  class FragmentSpread: Equatable {
    let definition: CompilationResult.FragmentDefinition
    let selectionSet: SelectionSet

    init(
      definition: CompilationResult.FragmentDefinition,
      selectionSet: SelectionSet
    ) {
      self.definition = definition
      self.selectionSet = selectionSet
    }

    static func == (lhs: IR.FragmentSpread, rhs: IR.FragmentSpread) -> Bool {
      lhs.definition == rhs.definition &&
      lhs.selectionSet == rhs.selectionSet
    }
  }
}
