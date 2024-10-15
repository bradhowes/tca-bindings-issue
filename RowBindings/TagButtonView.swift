import SwiftUI

public struct TagButtonView: View {
  let name: String
  let tag: TagModel.Key
  let isActive: Bool
  let activator: () -> Void

  public init(
    name: String,
    tag: TagModel.Key,
    isActive: Bool,
    activator: @escaping () -> Void
  ) {
    self.name = name
    self.tag = tag
    self.isActive = isActive
    self.activator = activator
  }

  public var body: some View {
    Button {
      activator()
    } label: {
      Text(name)
        .indicator(isActive)
    }
  }
}

#Preview {
  List {
    TagButtonView(
      name: "Inactive Foobar",
      tag: .init(.init(0)),
      isActive: true,
      activator: {}
    )
    TagButtonView(
      name: "Active Blah",
      tag: .init(.init(1)),
      isActive: false,
      activator: {}
    )
    .onCustomLongPressGesture {
      print("long press")
    }
  }
}

