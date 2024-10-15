import Foundation
import Tagged

public class TagModel: Equatable, Identifiable {

  public static func == (lhs: TagModel, rhs: TagModel) -> Bool {
    lhs.internalKey == rhs.internalKey
  }

  public var id: Key { key }

  public typealias Key = Tagged<TagModel, UUID>
  public let internalKey: UUID
  public var key: Key { .init(internalKey) }
  public var ordering: Int
  public var name: String
  public let ubiquitous: Bool

  public var isUbiquitous: Bool { ubiquitous }
  public var isUserDefined: Bool { !ubiquitous }

  public init(key: Key, ordering: Int, name: String, ubiquitous: Bool) {
    self.internalKey = key.rawValue
    self.ordering = ordering
    self.name = name
    self.ubiquitous = ubiquitous
  }
}

extension TagModel {

  nonisolated(unsafe) public static var activeTagKey: TagModel.Key = .init(.init(0))

  nonisolated(unsafe) public static var _tags: [TagModel] = [
    .init(key: .init(.init(0)), ordering: 0, name: "All", ubiquitous: true),
    .init(key: .init(.init(1)), ordering: 1, name: "Built-In", ubiquitous: true),
    .init(key: .init(.init(2)), ordering: 2, name: "Added", ubiquitous: true),
    .init(key: .init(.init(3)), ordering: 3, name: "External", ubiquitous: true),
    .init(key: .init(.init()), ordering: 4, name: "User Tag", ubiquitous: false),
  ]

  public static func tags() -> [TagModel] {
    _tags.sorted { $0.ordering < $1.ordering }
  }

  public static func fetch(key: TagModel.Key) -> TagModel {
    _tags.first(where: { $0.key == key })!
  }
  
  public static func create(name: String) -> TagModel {
    let value: TagModel = .init(key: .init(.init()), ordering: _tags.count, name: name, ubiquitous: false)
    _tags.append(value)
    return value
  }

  public static func delete(key: TagModel.Key) -> Void {
    _tags.removeAll { $0.key == key }
  }
}
