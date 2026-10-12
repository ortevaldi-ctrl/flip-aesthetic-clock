# FLIP — Aesthetic Clock

Aplicación nativa macOS, SwiftUI y AppKit. Versión 0.5.0: colección de 25 fondos, favoritos e icono original. No requiere paquetes externos ni conexión a internet.

## Aplicación y entorno

Paquete principal: `build/FLIP.app`. Proyecto: `FLIP.xcodeproj`. Compatible con Apple Silicon, macOS 14 o posterior. Compilado y probado en macOS 26.6.2, Xcode 26.6 y Swift 6.3.3.

La aplicación se abre como un paquete nativo desde Finder, sin ejecutar Xcode ni Codex. La firma es local ad hoc. No se ha realizado una sesión prolongada con ambos programas cerrados.

## Instalación y Dock

**Estado de esta sesión: instalación pendiente.** El intento autorizado de copiar a `/Applications/FLIP.app` falló con `Operation not permitted` debido a las restricciones de escritura del entorno. No había una instalación anterior y no se sobrescribió ningún archivo.

Para instalar desde Finder:

1. Abre `~/Projects/FLIP/build` y copia `FLIP.app`.
2. Abre la carpeta Aplicaciones y pega el paquete. Finder solicitará autenticación si el sistema la necesita.
3. Cierra cualquier copia de FLIP abierta desde el proyecto y abre `/Applications/FLIP.app`.
4. En el Dock, clic secundario sobre FLIP → Opciones → Mantener en el Dock.

También está preparado `Scripts/Install.sh` para ejecutarlo manualmente desde un Terminal normal. Comprueba la firma, copia con `ditto` y verifica la copia; se detiene sin sobrescribir si ya existe FLIP en Aplicaciones. El agente no puede ejecutarlo con acceso fuera del sandbox de esta sesión.

El icono está integrado en ambas compilaciones, pero queda pendiente observarlo en Finder, Dock, lanzador de aplicaciones y selector de aplicaciones después de instalar.

## Compilar y verificar

```sh
./Scripts/build.sh
./Scripts/test.sh
xcodebuild -project FLIP.xcodeproj -scheme FLIP -configuration Release -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData build CODE_SIGNING_ALLOWED=NO
```

El script genera el icono mediante gráficos originales AppKit/Core Graphics, codifica sus representaciones PNG en un contenedor ICNS y produce un ejecutable optimizado arm64 con firma ad hoc. Xcode incluye `Resources/FLIP.icns` en su fase de recursos. `Info.plist` declara `CFBundleIconFile = FLIP.icns`. El archivo ICNS ha sido decodificado y validado por AppKit/ImageIO y `sips`.

Recursos del icono: `Resources/FLIP-master-1024.png`, `Resources/FLIP.iconset/` y `Resources/FLIP.icns`. No utiliza iconos descargados ni fuentes externas.

## Uso

La barra empieza visible. Un movimiento real del cursor reinicia el plazo monotónico de diez segundos. Los controles desaparecen con fundido de 0,4 s, incluyendo material y sombras, y reaparecen con fundido de 0,2 s. Permanecen visibles mientras la galería o la personalización están abiertas. El cursor solo se oculta en pantalla completa cuando la ventana es la activa y reaparece por movimiento según el mecanismo nativo de macOS.

Atajos: ⌘B galería, ⌘, personalización, ⌃⌘F pantalla completa, Esc salir. En la galería, cada estrella permite añadir/quitar un favorito y el filtro Favoritos facilita el acceso. Preferencias y favoritos se guardan en UserDefaults, dominio exclusivo `com.flip.aestheticclock`.

## Colección de 25 fondos

1. Minimal Black
2. Dark Gradient
3. Frosted Glass
4. Monochrome Aurora
5. Liquid Chrome
6. Topographic
7. Mountain
8. Dark Ocean
9. Space
10. Moon
11. Night City
12. White Neon
13. Technical Grid
14. Abstract Metal
15. Particles
16. Waves
17. Brushed Titanium
18. Carbon Fiber
19. Vertical Split
20. Outline
21. Dot Matrix
22. Retro Film
23. Earth
24. Minimal Lines
25. Black Silk

Se conservaron los quince primeros. Earth es una ilustración original estilizada con continentes y nubes; se distingue del planeta de Space. Los fondos son gráficos procedurales locales monocromáticos. No hay imágenes remotas ni servicios de pago.

## Arquitectura y optimización

- `TimeEngine.swift`: hora real como fuente de verdad, plazos alineados a segundos/minutos, despertar y zona horaria, pausa/resincronización.
- `FlipCard.swift`: hojas divididas, animación 3D por mitades, perspectiva y sombra según el ángulo. Mismo mecanismo en toda la colección.
- `ClockFace.swift`: aísla las actualizaciones horarias del resto de la escena. Si no se muestran segundos, actualiza al siguiente minuto; si no es visible, pausa.
- `Backgrounds.swift`: catálogo y composición de fondos iniciales.
- `CollectionBackground.swift`: diez fondos de fase 4A.
- `PremiumBackground.swift`: diez fondos de fase 4B.
- `WindowVisibility.swift`: observa ocultación, minimización y oclusión de la ventana y de la aplicación para pausar actividad gráfica.
- `ControlsActivity.swift`: implementación de fase 4A conservada sin reescritura.
- `FavoritesStore.swift`: preferencias de favoritos, lectura compatible con arrays y JSON, conservación de nombres desconocidos y preferencias ajenas.
- `BackgroundGallery.swift` y `ClockPreferences.swift`: galería, favoritos y personalización inicial.

Aurora, Liquid Chrome, Dark Ocean, Particles y Waves tienen movimiento lento limitado a 24 fps. Las miniaturas y otros veinte fondos son estáticos. Las actualizaciones del reloj no invalidan toda la escena. Se respeta Reducir movimiento tanto en fondos como en giros Flip.

## Verificación y límites

- Compilación Release de Xcode correcta, paquete optimizado arm64 y firma local válidos; icono presente en ambos paquetes.
- Render local y revisión visual de los 25 estilos. Imágenes en `build/QA/`; lámina de los diez nuevos en `build/QA/phase4B-contact-sheet.png`.
- Pruebas de medianoche, mediodía, formato 12/24 h, cambio de día y conversión de zona horaria.
- Pruebas del plazo exacto de diez segundos, eventos estacionarios, movimiento, pausa/reinicio de paneles. No se modificó esta lógica en fase 4B.
- Pruebas de favoritos: añadir, quitar, recargar, compatibilidad JSON, nombres desconocidos y conservación de otras preferencias.
- Prueba de pausa del motor oculto y resincronización inmediata con hora real.
- Apertura nativa de la versión 0.5 y observación de galería con 25 fondos y estrellas de favoritos. En fase 4A se verificó individualmente la selección de los quince originales. El recorrido automatizado de selecciones de fase 4B fue interrumpido por cambios de estado de la interfaz; no se declara como completado.
- Medición de render estático fuera de pantalla a 1100 × 720: los 25 renders tardaron 0,058 s en esta ejecución. Resultado detallado en `build/render-benchmark.txt`. No equivale a una medición de CPU/GPU, fluidez sostenida o consumo energético en ejecución real.

Pendientes: instalación manual debido al sandbox; comprobación visual del icono en las superficies de macOS después de instalar; selección individual de los diez nuevos en interfaz; medición sostenida de CPU/GPU, memoria y energía; pruebas prolongadas y suspensión física. No se ha desactivado la conexión del Mac como prueba, aunque el código y todos los recursos son offline.

La herramienta de automatización ha devuelto fallos de ventana y cambios de estado externos; por ello se conserva la limitación de verificación visual del cursor indicada en fase 4A. Los timers de macOS pueden ejecutarse después de su plazo si el hilo principal está ocupado.

## Versión iPhone (migración inicial)

Se ha añadido un proyecto independiente en `iOS/FLIP-iOS.xcodeproj`, esquema `FLIP-iOS`, para iPhone con iOS 17 o posterior. Comparte el reloj flip, los 25 fondos, favoritos y ajustes, con pantalla táctil adaptativa. Compilaciones iOS Simulator Debug e iPhoneOS Release sin firma verificadas; ejecución visual pendiente por faltar el runtime y un dispositivo conectado. El target macOS y `/Applications/FLIP.app` se conservan. Detalles, fases y pasos de instalación gratuita: [iOS/README.md](iOS/README.md).
