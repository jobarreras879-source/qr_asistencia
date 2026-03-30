🎨 Paleta: [Mejora de UX]

¿Qué?: Reemplazo de `GestureDetector` por `InkWell` (dentro de un `Material` transparente e `Ink` para la decoración) en la cuadrícula de acciones de la pantalla principal y en el botón de llamada a la acción (CTA).
Por qué: Los elementos interactivos (botones/tarjetas de acción) en la pantalla principal no daban ningún tipo de retroalimentación visual al ser presionados. Esto causaba incertidumbre sobre si la acción se había registrado, dando una percepción de lentitud en la interfaz. Al añadir el efecto ripple nativo, la interacción se vuelve inmediatamente evidente y receptiva para el usuario.
Accesibilidad: Mejora la claridad interactiva. Aunque visual, proporciona una confirmación implícita de que un área es clicable y está respondiendo al toque del usuario.
