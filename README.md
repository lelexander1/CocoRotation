# CocoRotation

Addon original para Druida en WoW Mists of Pandaria Classic.

[Descargar la última versión](https://github.com/lelexander1/CocoRotation/releases/latest)

Extrae `CocoRotation` en `_classic_/Interface/AddOns/` y usa `/reload`.

- Rotación de Equilibrio con un solo icono: `/coco`.
- Valoración orientativa de equipo para cuatro especializaciones.
- Barras de daño realizado/recibido y DPS: `/cocodmg`.

[Instrucciones completas y limitaciones](CocoRotation/README.md).

## Desarrollo y publicaciones

Cada push a main ejecuta pruebas en Lua 5.1, construye el ZIP y crea un lanzamiento automático asociado al commit. Solo publica si las pruebas pasan. Las solicitudes de cambio ejecutan pruebas sin publicar. Los ZIP conservan la carpeta instalable CocoRotation en su raíz. GitHub Actions usa su token integrado; no necesita guardar una clave personal.

Prueba local: `lua5.1 tests/test.lua` desde la raíz.

Las pruebas usan API simuladas: no reemplazan una prueba en el cliente real.
No se actualiza la instalación de WoW automáticamente desde el addon.
