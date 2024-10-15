import ComposableArchitecture
import SwiftUI

@Reducer
public struct TagsList {

  @Reducer(action: .sendable)
  public enum Destination {
    case alert(AlertState<Alert>)
    case edit(TagsEditor)

    @CasePathable
    public enum Alert: Equatable, Sendable {
      case confirmDeletion(key: TagModel.Key)
    }
  }

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?
    var tags: IdentifiedArrayOf<TagModel>
    var activeTagKey: TagModel.Key

    public init(tags: IdentifiedArrayOf<TagModel>, activeTagKey: TagModel.Key) {
      self.tags = tags
      self.activeTagKey = activeTagKey
    }
  }

  public enum Action: Sendable {
    case addButtonTapped
    case cancelEditButtonTapped
    case confirmDeletion(key: TagModel.Key)
    case deleteButtonTapped(key: TagModel.Key, name: String)
    case destination(PresentationAction<Destination.Action>)
    case doneEditingButtonTapped
    case fetchTags
    case longPressGestureFired
    case tagButtonTapped(key: TagModel.Key)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {

      case .addButtonTapped:
        addTag(&state)
        return .none

      case .cancelEditButtonTapped:
        state.destination = nil
        fetchTags(&state)
        return .none

      case .confirmDeletion(let key):
        deleteTag(&state, key: key)
        return .run { _ in
          @Dependency(\.dismiss) var dismiss
          await dismiss()
        }

      case let .deleteButtonTapped(key, name):
        state.destination = .alert(.deleteTag(key, name: name))
        return .none

      case .destination(.presented(.alert(let alertAction))):
        switch alertAction {
        case .confirmDeletion(let key):
          deleteTag(&state, key: key)
        }
        return .none

      case .destination:
        return .none

      case .doneEditingButtonTapped:
        state.destination = nil
        return .none

      case .fetchTags:
        fetchTags(&state)
        return .none

      case .longPressGestureFired:
        state.destination = .edit(TagsEditor.State(tags: state.tags))
        return .none

      case .tagButtonTapped(let key):
        state.activeTagKey = key
        TagModel.activeTagKey = key
        return .none

      @unknown default:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension TagsList.Destination.State: Equatable {}

extension TagsList {

  private func addTag(_ state: inout State) {
    _ = TagModel.create(name: "New Tag")
    fetchTags(&state)
  }

  private func fetchTags(_ state: inout State) {
    state.tags = .init(uniqueElements: TagModel.tags())
  }

  private func deleteTag(_ state: inout State, key: TagModel.Key) {
    if state.activeTagKey == key {
      state.activeTagKey = TagModel.tags().first!.key
    }
    state.tags = state.tags.filter { $0.key != key }
    TagModel.delete(key: key)
  }
}

extension AlertState where Action == TagsList.Destination.Alert {
  public static func deleteTag(_ key: TagModel.Key, name: String) -> Self {
    .init {
      TextState("Delete?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeletion(key: key)) {
        TextState("Yes")
      }
      ButtonState(role: .cancel) {
        TextState("No")
      }
    } message: {
      TextState("Are you sure you want to delete tag \"\(name)\"?")
    }
  }
}

public struct TagsListView: View {
  @Bindable private var store: StoreOf<TagsList>

  public init(store: StoreOf<TagsList>) {
    self.store = store
  }

  public var body: some View {
    List(store.tags, id: \.key) { tag in
      TagButtonView(
        name: tag.name,
        tag: tag.key,
        isActive: tag.key == store.activeTagKey
      ) {
        store.send(.tagButtonTapped(key: tag.key))
      }
      .onCustomLongPressGesture {
        store.send(.longPressGestureFired)
      }
      .swipeActions(allowsFullSwipe: false) {
        if !tag.ubiquitous {
          Button(role: .destructive) {
            store.send(.deleteButtonTapped(key: tag.key, name: tag.name))
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
      }
      .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
    HStack {
      Button {
        _ = store.send(.addButtonTapped)
      } label: {
        Image(systemName: "plus")
      }
    }
    .onAppear() {
      _ = store.send(.fetchTags)
    }
    .sheet(
      item: $store.scope(state: \.destination?.edit, action: \.destination.edit)
    ) { tagEditStore in
      NavigationStack {
        TagsEditorView(store: tagEditStore)
          .navigationTitle("Tags")
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Dismiss") {
                store.send(.cancelEditButtonTapped)
              }
            }
            ToolbarItem(placement: .automatic) {
              Button {
                tagEditStore.send(.addButtonTapped)
              } label: {
                Image(systemName: "plus")
              }
            }
            ToolbarItem(placement: .automatic) {
              EditButton()
            }
          }
      }
    }
  }
}

extension TagsListView {
  static var preview: some View {
    let tags = TagModel.tags()
    return TagsListView(
      store: Store(
        initialState: .init(
          tags: .init(uniqueElements: tags),
          activeTagKey: tags[0].key
        )) {
          TagsList()
        }
    )
  }
}

#Preview {
  TagsListView.preview
}

