# Introduction

Demonstration of a perplexing binding issue in TCA. When run, the app shows a list of tags. Long-pressinig on a tag
brings up the tags editor. Tags may be moved around, added, and removed with no issue. The problem appears when
attempting to edit the "User Tag" name (the other tags are read-only and cannot be changed).

- Clicking on "User Tag" text brings up the keyboard and allows editing

- The Xcode console shows a warning:

```
A binding action sent from a store was not handled. …

  Action:
    TagNameEditor.Action.binding(.set(_, "User Tag"))

To fix this, invoke "BindingReducer()" from your feature reducer's "body".
```

- Typing letters will repeat this message

- Setting a breakpoint in `BindableActionDebugger`, I can print out the key path of the action:

```
(lldb) p keyPath
(WritableKeyPath<State, Value> & Sendable) {
  object = 0x000060000178ff40 {
    Swift.KeyPath<RowBindings.TagNameEditor.State, Swift.String> = {
      Swift.PartialKeyPath<RowBindings.TagNameEditor.State> = {
        Swift.AnyKeyPath = {
          _kvcKeyPathStringPtr = nil
        }
      }
    }
  }
  wtable = 0x00000001025a88b8 type metadata for RowBindings.TagNameEditor.State
}
```

The code for the `TagNamesEditor` appears to be set up properly to register and process SwiftUI bindings to attributes
in the `TagNameEditor.State`.
