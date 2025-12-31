# Mojo Coding Rules
1. Always ground code generation in the `modular/modular` repository.
2. Use `fn` by default for performance; only use `def` for Python compatibility.
3. If a standard library function is unknown, search the remote Modular stdlib folder 
   via the integrated browser before hallucinating a solution.

# Mojo Coding Standards
- **Prohibited:** Never use Python's `list` or `dict` for performance-critical loops; use `utils.vector.DynamicVector` or native `Dict`.
- **Prohibited:** Do not use `import numpy`; use Mojo's `MAX` or native SIMD operations for tensor math unless explicitly requested for interoperability.
- **Verification:** Before finishing a task, the agent must check the `stdlib` folder in the indexed `modular/modular` repo to ensure the function signature matches.
- Use the latest Mojo syntax (2024/2025).
- Always use `var` for mutable variables; avoid the deprecated `let`.
- Prefer Mojo-native types: `Int`, `Float64`, `Bool`, `String`.
- Use `struct` for stack-allocated types and `fn` for strict typing.
- When using `PythonInterface`, always wrap calls in `try/except` blocks.
- Follow the "Value Semantics" pattern (use `__init__`, `__copyinit__`, and `__moveinit__`).

# Memory Safety Rules
- Use `borrowed` for read-only access to avoid unnecessary copies.
- Use `owned` for transferring ownership.
- If the agent detects a potential lifetime issue, it must search the "Lifetimes" section of the Modular docs using the integrated browser.
