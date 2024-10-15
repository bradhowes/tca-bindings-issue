import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    var body: some View {
      let tags = TagModel.tags()
      TagsListView(
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
    ContentView()
}
