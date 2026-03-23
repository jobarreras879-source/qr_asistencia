# Instrucciones de Verificación de Dominio

Para solucionar el error de "sitio no registrado", debes seguir estos pasos para verificar tu dominio en Google Search Console. Google necesita confirmar que eres el dueño de `https://jobarreras879-source.github.io/qr_asistencia/`.

## Pasos a seguir:

1. **Subir los cambios**: Asegúrate de hacer `git push` de los cambios en `index.html` para que el sitio GitHub Pages se actualice.
2. **Acceder a Google Search Console**:
   - Ve a [https://search.google.com/search-console](https://search.google.com/search-console).
   - Inicia sesión con la **misma cuenta** que usas en Google Cloud Console.
3. **Añadir una Propiedad**:
   - Haz clic en "Añadir propiedad" (en la esquina superior izquierda).
   - Selecciona el tipo **Prefijo de la URL**.
   - Ingresa: `https://jobarreras879-source.github.io/qr_asistencia/`
   - Haz clic en **Continuar**.
4. **Método de Verificación**:
   - Google intentará verificar automáticamente usando la **Etiqueta HTML** (Meta tag) que ya hemos incluido en tu archivo `index.html`.
   - Si no lo hace automáticamente, busca la opción "Etiqueta HTML" y haz clic en **Verificar**.
5. **Completar en Google Cloud**:
   - Una vez que Google Search Console diga "Propiedad verificada", vuelve a la consola de Google Cloud y haz clic en "Corregí los problemas" para reenviar a revisión.

> [!IMPORTANT]
> Es crucial que uses la misma cuenta de Gmail tanto para Google Search Console como para Google Cloud Console para que la verificación se asocie correctamente.
