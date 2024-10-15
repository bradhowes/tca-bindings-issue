import ComposableArchitecture
import SwiftUI
import SwiftUINavigation

@Reducer
public struct TagsEditor {

  @ObservableState
  public struct State: Equatable {
    var rows: IdentifiedArrayOf<TagNameEditor.State>

    public init(tags: IdentifiedArrayOf<TagModel>) {
      self.rows = .init(uniqueElements: tags.map{ .init(tag: $0) })
    }
  }

  public enum Action: Equatable, Sendable {
    case addButtonTapped
    case deleteButtonTapped(IndexSet)
    case rows(IdentifiedActionOf<TagNameEditor>)
    case tagMoved(at: IndexSet, to: Int)
    case tagNameChanged
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        addTag(&state)
        return .none

      case let .deleteButtonTapped(indices):
        deleteTag(&state, at: indices)
        return .none

      case .rows:
        return .none

      case let .tagMoved(indices, offset):
        moveTag(&state, at: indices, to: offset)
        return .none

      case .tagNameChanged:
        saveChanges(state)
        return .none
      }
    }
  }

  private func addTag(_ state: inout State) {
    let tag = TagModel.create(name: "New Tag")
    state.rows.append(.init(tag: tag))
  }

  private func deleteTag(_ state: inout State, at indices: IndexSet) {
    if let index = indices.first {
      let key = state.rows[index].key
      state.rows.remove(atOffsets: indices)
      TagModel.delete(key: key)
    }
  }

  private func moveTag(_ state: inout State, at indices: IndexSet, to offset: Int) {
    state.rows.move(fromOffsets: indices, toOffset: offset)
    for (index, tagInfo) in state.rows.elements.enumerated() {
      let tag = TagModel.fetch(key: tagInfo.key)
      tag.ordering = index
    }
  }

  private func saveChanges(_ state: State) {
    for tagInfo in state.rows.elements {
      let tag = TagModel.fetch(key: tagInfo.key)
      tag.name = tagInfo.name
    }
  }
}

public struct TagsEditorView: View {
  @Bindable private var store: StoreOf<TagsEditor>

  public init(store: StoreOf<TagsEditor>) {
    self.store = store
  }

  public var body: some View {
    List {
      ForEach(store.scope(state: \.rows, action: \.rows), id: \.state.key) { store in
        TagNameEditorView(store: store)
      }
      .onMove { store.send(.tagMoved(at: $0, to: $1)) }
      .onDelete { store.send(.deleteButtonTapped($0)) }
    }
  }
}
