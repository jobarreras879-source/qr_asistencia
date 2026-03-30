2026-03-24 - Improve tap visual feedback in HomeScreen

Aprendizaje: The action grid and CTA buttons in `HomeScreen` used `GestureDetector`, which does not provide visual feedback when pressed, making the interface feel unresponsive. Replacing them with `Material` and `InkWell` (along with `Ink` to maintain visual styling) adds a standard ripple effect, improving usability and the perceived reactivity of the app.
