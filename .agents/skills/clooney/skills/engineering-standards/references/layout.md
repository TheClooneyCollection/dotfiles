# Multiline layout

Make nested structure visible while keeping complete short expressions compact.

17. **Show each level.** Keep a complete short call, declaration or condition list on one line when it fits. Once it spans lines, show each item and nesting level separately. Swift forms:

    **Conditions.** Put `guard`, `if` or `while` on its own line, each comma-separated condition on its own indented line, and `else {` or `{` on its own line aligned with the keyword. Conditional bodies span lines even when the condition list is short. Commas inside patterns or calls do not separate conditions.

    ```swift
    guard
        case let .loaded(items) = state,
        !items.isEmpty
    else {
        return
    }
    ```

    **Arguments and parameters.** In a multiline call or declaration, put each argument or parameter on its own line with trailing commas. Trailing commas in argument and parameter lists need Swift 6.1 or later; on older toolchains, omit the final comma. Initializer parameters have no blank lines between groups, as in rule 15.

    **Nested calls.** If an inner call spans lines, expand its enclosing call too. Give each opening argument boundary and closing parenthesis its own nesting level and line; never combine closing parentheses as `))`.

    ```swift
    state = .loaded(
        ListContent(
            items: items,
            selection: nil,
        ),
    )
    ```
