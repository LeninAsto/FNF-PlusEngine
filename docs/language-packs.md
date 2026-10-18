# Paquetes de idioma de Plus Engine

`assets/shared/languages/en-US` es la fuente canónica. Cada idioma replica sus archivos y claves; sólo cambian los textos visibles. El engine carga primero `en-US` como respaldo y después aplica el idioma elegido.

## Crear un paquete

1. Copia `assets/shared/languages/en-US` a una carpeta con un código BCP 47, por ejemplo `pt-BR`.
2. Traduce los valores de texto. Conserva las claves, los `$namespace`, las rutas, los saltos de línea y marcadores como `{1}`, `{2}`, `%v` y `%d`.
3. Edita su `manifest.json`:

```json
{
  "schemaVersion": 1,
  "code": "pt-BR",
  "name": "Português (Brasil)",
  "version": 1,
  "fallback": ["en-US"],
  "bundles": ["global.json", "options/common.json"]
}
```

4. Agrega el idioma a `assets/shared/languages/index.json`:

```json
{
  "code": "pt-BR",
  "name": "Português (Brasil)",
  "version": 1
}
```

5. Abre un pull request hacia `Psych-Plus-Team/FNF-PlusEngine`. Al fusionarse en `main`, el catálogo y los archivos quedan disponibles por GitHub Raw.

Para publicar una corrección, aumenta `version` tanto en el manifiesto como en el índice. Si la versión no aumenta, los clientes que ya tengan el paquete lo considerarán actualizado.

## Descarga OTA

En **Opciones > Idioma**, la acción **Descargar o actualizar idiomas** obtiene el índice oficial por HTTPS. Para cada idioma nuevo o con una versión mayor, el engine:

1. descarga el manifiesto y todos sus bundles;
2. rechaza códigos, rutas o tamaños inseguros;
3. analiza todos los JSON y exige `$namespace` antes de escribirlos;
4. guarda los bundles en `mods/languages/<código>/`;
5. escribe el manifiesto al final para que una descarga interrumpida nunca quede activa.

El selector muestra automáticamente los paquetes instalados. Los archivos descargados viven fuera del ejecutable, por lo que pueden actualizarse sin recompilar el engine.

## Reglas de calidad

- Usa UTF-8 y revisa indicadores de mojibake como `U+00C3`, `U+00C2` o el carácter de reemplazo `U+FFFD`.
- Mantén intactos los marcadores y nombres técnicos.
- Prefiere etiquetas breves, cercanas al tamaño del inglés, para evitar cortes en botones y editores.
- Prueba el idioma en 1280×720 y revisa especialmente Opciones, Chart Editor, popups y mensajes de error.
