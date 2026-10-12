# CocoRotation 1.2.0

Asistente visual para Druida Equilibrio en WoW Mists of Pandaria Classic (interfaces 50500–50504). Código original, sin dependencia de Hekili ni bibliotecas externas. Recomienda una habilidad mediante su icono; el jugador la ejecuta desde su barra habitual.

## Instalación
1. Cierra WoW o vuelve a la selección de personajes.
2. Extrae CocoRotation-1.2.0.zip en la carpeta de tu instalación de MoP Classic: `_classic_\Interface\AddOns\`.
3. Comprueba que quede `AddOns\CocoRotation\CocoRotation.toc`, sin una carpeta adicional intermedia.
4. Activa CocoRotation en el menú AddOns. Entra con tu Druida Equilibrio.
5. Escribe `/coco` para abrir las opciones. Si ya estabas conectado, usa `/reload`.

## Uso y configuración
La interfaz muestra únicamente el icono de la habilidad recomendada, de 52 × 52 píxeles, con el barrido visual de cooldown sin cifras. No muestra textos ni fondo; se oculta cuando no hay una recomendación. Se actualiza aproximadamente ocho veces por segundo. Arrastra el icono con el botón izquierdo cuando esté desbloqueado; el botón derecho abre opciones. Las preferencias se guardan entre sesiones y son compartidas por la cuenta.

- `/coco pve`: prioridades de combate con cooldowns ofensivos.
- `/coco leveo`: recuperación de salud bajo 35%; reserva Encarnación, Alineación, Vigilia y treants para élites y jefes.
- `/coco objetivos 3`: cambia el número de objetivos considerado, de 1 a 20. No cuenta enemigos automáticamente.
- `/coco escala 1.2`: escala entre 0.5 y 2.
- `/coco opacidad 0.8`: opacidad entre 0.2 y 1.
- `/coco reset`: restaura preferencias y posición.
- `/coco estado`: muestra interfaz del cliente, dirección y energía de Eclipse para diagnóstico.
- `/coco ayuda`: resumen de comandos.

Las opciones permiten activar/desactivar el asistente, cooldowns, Lluvia de estrellas, Huracán, bloqueo y visibilidad solo en combate. Lluvia de estrellas está desactivada inicialmente: actívala cuando el área sea apropiada. Huracán requiere activar AoE y establecer al menos tres objetivos. Puedes abrir opciones mediante /coco aunque el panel esté bloqueado u oculto.

## Motor de recomendaciones
- Usa auras de Eclipse lunar/solar y la dirección de la barra: Cólera hacia lunar, Fuego estelar hacia solar. Durante Alineación recomienda Fuego estelar.
- Prioriza Estrellas fugaces para consumir el proc de Oleada de estrellas.
- Mantiene Fuego lunar y Fuego solar del jugador en el objetivo, con un margen que considera lanzamiento/GCD. Durante Alineación evita recomendar Fuego solar por separado.
- Recomienda Encarnación en Eclipse lunar, Vigilia durante Eclipse y Alineación fuera de Eclipse. Solo ofrece habilidades conocidas y disponibles.
- Considera cargas de Fuerza de la Naturaleza, movimiento, alcance cuando la API lo informa, recursos, cooldowns y habilidades aún no aprendidas.
- Sueño de Cenarius: propone Toque de sanación cerca del siguiente Eclipse (energía absoluta >=70), si falta su beneficio y el personaje está quieto. Alma del bosque y Corazón de lo Salvaje afectan el personaje pasivamente; el motor lee el estado real resultante. No activa Corazón de lo Salvaje para una rotación híbrida.
- Leveo prioriza Renovación o Toque de sanación para supervivencia; Estimular aparece con maná bajo 20%.
- Durante movimiento ofrece instantáneos. Respeta canalizaciones y evita duplicar un lanzamiento de cooldown ya en curso.

## Alcance de esta versión
Es un asistente de prioridad para el estado actual, con una sugerencia visible. No implementa la simulación de múltiples acciones futuras de Hekili, estimación de tiempo de muerte, selección automática de objetivos, multidot automático, optimización por equipo, snapshot completo de DoT ni coordinación con el grupo. El refresco de DoT es por duración: no compara todos los posibles beneficios de volver a aplicarlos al entrar en Eclipse. No incluye preparación automática con Comunión astral, abalorios ni rotación de sanador/tanque. El motor adapta disponibilidad de talentos activos sin exigir una build fija.

## Verificación y prueba en el juego
Verificado fuera del juego: compilación de los dos archivos Lua, 29 escenarios del motor, carga del addon con API simulada moderna y antigua, comandos, opciones y guardado de preferencias. No se ha ejecutado en un cliente real de WoW; las pruebas simuladas no validan la presentación visual ni cada API del cliente instalado.

Prueba recomendada con un muñeco: observa un ciclo completo lunar/solar; comprueba que desaparezcan sugerencias de talentos no seleccionados; prueba Estrellas fugaces, Alineación, movimiento y cambio de objetivo; activa/desactiva cooldowns y AoE; recarga para verificar posición y opciones. Prueba leveo con enemigos normales y élites. Para investigar errores usa `/console scriptErrors 1`, después `/reload`, y registra el error y `/coco estado`.

## Referencias de compatibilidad
La lectura de dirección sigue la semántica documentada de GetEclipseDirection (dirección hacia el siguiente Eclipse). El adaptador contempla C_Spell y los accesos heredados.
- API del cliente: https://github.com/Gethe/wow-ui-source/tree/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated
- Referencia GetEclipseDirection: https://warcraft.wiki.gg/wiki/API_GetEclipseDirection
- Formato TOC: https://warcraft.wiki.gg/wiki/TOC_format

World of Warcraft y sus marcas pertenecen a Blizzard Entertainment. CocoRotation no está afiliado a Blizzard ni a Hekili.



## Nuevo en 1.1.0: equipo y daño de mazmorra

La rotación sigue mostrando solo un icono. Las funciones nuevas son independientes.

### Equipo para las cuatro especializaciones de Druida
Pasa el cursor sobre un objeto equipable de bolsa, botín o enlace del chat: su descripción añade puntuaciones para Equilibrio, Feral, Guardián y Restauración. Cada puntuación compara las estadísticas disponibles con las del objeto equipado en esa ranura. Para anillos y abalorios compara con la ranura de menor puntuación.

Son pesos genéricos de orientación, definidos en `Extras.lua` (gearProfiles), no pesos simulados del personaje ni una lista de mejores objetos de cada fase. Los puntos entre especializaciones no son comparables: compara dos objetos dentro de la misma especialización. Intelecto favorece Equilibrio y Restauración; agilidad, Feral y Guardián. La valoración excluye límites de golpe/pericia, puntos de haste, conversión exacta de espíritu, DPS de arma, procs, gemas, encantamientos y bonos de conjunto. No tomes una puntuación superior como una mejora garantizada: revisa especialmente armas, abalorios y piezas de conjunto. Con armas de dos manos debes considerar también la pérdida del objeto de mano izquierda. Si la información de un objeto no está cargada, vuelve a pasar el cursor después de que el cliente la reciba.

### Daño realizado y recibido
- `/cocodmg`: abre/cierra una ventana independiente y movible.
- `Realizado / recibido`: alterna entre daño realizado con DPS y daño recibido con daño por segundo.
- `/cocodmg reset` o el botón Reiniciar sesión: pone a cero los datos.

Registra combates en mazmorras y bandas. Comienza una sesión al entrar y conserva el resultado al salir; al volver a entrar comienza otra sesión. Los datos son de la sesión en memoria y se pierden al recargar o cerrar el juego. Se muestran los primeros 12 jugadores ordenados por daño; el total incluye todos los jugadores registrados de la sesión, incluso si salen del grupo.

El daño efectivo excluye overkill. Incluye ataques cuerpo a cuerpo, hechizos, daño periódico, ataques a distancia y daño ambiental recibido por jugadores. El daño realizado por mascotas e invocaciones identificadas se atribuye a su dueño; el daño recibido por mascotas no se suma a los jugadores. El DPS usa un denominador común: segundos durante los cuales al menos un miembro actual del grupo está en combate. No equivale al DPS de tiempo activo individual de otros medidores.

El registro depende del alcance del log de combate del cliente. Daño ocurrido lejos del personaje o antes de cargar el addon puede faltar. No sincroniza datos con otros jugadores, no resta absorciones una segunda vez y no muestra aún historial por jefe, sanación o desglose por habilidad.

Pruebas locales adicionales: puntuación para cuatro especializaciones y estadísticas ausentes, daño efectivo y overkill, lectura de eventos de daño, atribución de mascotas, temporizador, apertura del medidor y conservación/reinicio de sesiones al salir/entrar. Falta verificar las nuevas ventanas y descripciones de objetos en un cliente real de MoP Classic.


## Nuevo en 1.2.0: resultados claros y medidor con barras

La descripción de objetos muestra primero tu especialización activa y un resultado coloreado:
- Verde: MEJORA ESTIMADA según los pesos de estadísticas.
- Rojo: PEOR POR ESTADÍSTICAS, o NO EQUIPABLE POR DRUIDA para tipos de armas/armaduras no permitidos.
- Gris: SIMILAR POR ESTADÍSTICAS.
- Amarillo: REVISAR cuando faltan datos o para abalorios y armas Feral/Guardián, cuyo efecto/DPS no se calcula.

Aparece el cambio de puntos y porcentaje frente a lo equipado. Ese porcentaje corresponde a la puntuación de estadísticas, no al aumento de daño o sanación. Una mejora estimada todavía puede perder valor al superar caps o romper un bono de conjunto. Las armas de dos manos consideran también las estadísticas de la mano izquierda actual. Se reintenta la valoración cuando el cliente termina de cargar un objeto y se añaden valoraciones en tooltips de comparación. Los puntos siguen siendo una heurística, sin base de datos BiS ni simulación.

El hacha de la captura no es equipable por un druida; usa armas permitidas y revisa las estadísticas de tu especialización.

El medidor `/cocodmg` ahora presenta barras horizontales ordenadas por daño, colores de clase, nombre, daño, DPS (o daño recibido por segundo) y porcentaje del total. Tiene una ventana movible, botón para cambiar realizado/recibido y reinicio. Mantiene el total de la sesión de mazmorra y la rotación sigue siendo solo un icono.

La presentación está inspirada en medidores como Details; no incorpora su código ni todas sus funciones. Esta versión todavía no ofrece segmentos por combate, historial, desglose por hechizo, sanación o sincronización entre jugadores. Las pruebas locales cubren también los resultados de mejora/peor/revisar, restricción de hachas, prioridad de especialización activa y prevención de duplicados en tooltips. Pendiente de prueba visual dentro del cliente real.

## Corrección 1.2.1: estabilidad de las descripciones
Se retiró la actualización repetida de tooltips y las llamadas Show al añadir valoraciones. Ahora CocoRotation solo añade líneas cuando WoW construye la descripción y evita llamadas recursivas. No modifica las ventanas de comparación equipadas. Si faltan datos de un objeto, vuelve a pasar el cursor después de que el cliente los cargue. Este cambio corrige una posible causa de parpadeo; requiere confirmar el resultado dentro del juego.

Repositorio oficial: https://github.com/lelexander1/CocoRotation
Descargas automáticas: https://github.com/lelexander1/CocoRotation/releases/latest
Cada cambio subido a main ejecuta pruebas y publica un ZIP si pasan. La publicación no instala archivos en WoW; descarga el ZIP y reemplaza la carpeta CocoRotation, o configura un gestor compatible con lanzamientos de GitHub.
