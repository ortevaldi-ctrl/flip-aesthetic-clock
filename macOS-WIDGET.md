# FLIP — widget macOS, versión 0.7.0

WidgetKit nativo para macOS 14 o posterior. Dos tamaños: pequeño y mediano. Muestra hora de 24 h y fecha del sistema mediante tarjetas monocromáticas estáticas. Pulsarlo utiliza `flip-clock://open/clock` para abrir FLIP. No incluye temporizador, segundos ni animación flip continua.

## Qué cambia y qué se conserva

- `Sources/Widget/FLIPClockWidget.swift`: extensión WidgetKit, provider, configuración y previews pequeño/mediano.
- `Sources/Widget/WidgetClockModel.swift`: proyección de hora/fecha y fechas de la timeline.
- `Sources/Widget/WidgetClockView.swift`: diseño compacto negro/gris, tarjetas legibles y accesibilidad.
- `Sources/Widget/WidgetLink.swift`: URL y validación compartidas entre app y extensión.
- `Sources/Widget/Info.plist` y `FLIPWidget.entitlements`: punto de extensión y App Sandbox, sin permisos de red ni App Groups.
- `FLIP.xcodeproj/project.pbxproj`: target `FLIPWidgets`, dependencia del target FLIP y fase **Embed App Extensions** con firma al copiar; firma automática y el mismo Personal Team en ambos targets.
- `FLIP.xcodeproj/xcshareddata/xcschemes/FLIP-With-Widget.xcscheme` y `FLIP.xcscheme`: esquemas compartidos para ejecutar la aplicación contenedora, construyendo también la extensión.
- `Sources/FLIP/FLIPApp.swift`: recepción del enlace y activación de la app; conserva la sesión del temporizador y la ventana.
- `Info.plist`: registra el esquema URL y actualiza macOS a 0.7.0/build 7; la extensión usa la misma versión.
- `Scripts/build-widget-preview.sh`: compilación aislada sin firma o intento de firma de desarrollo.
- `Scripts/build.sh` y `build-mac-countdown.sh`: incluyen la extensión al construir y sellan primero la extensión en las compilaciones locales ad hoc. La firma ad hoc no se presenta como verificación de carga de WidgetKit.
- `Tests/WidgetChecks.swift` y `Scripts/test-widget.sh`: pruebas de timeline, cambios de día/horario, enlace y renders en cuatro dimensiones.

El código de reloj, temporizador, fondos, preferencias, favoritos y controles existentes no se modificó. La extensión no comparte preferencias ni almacenamiento con la app: toma hora/fecha del sistema y tiene una apariencia fija. Por eso no necesita App Groups.

La versión iPhone, su proyecto y el motor compartido permanecen idénticos. `/Applications/FLIP.app` conserva exactamente los mismos hashes de ejecutable, Info.plist e icono. No se reinstaló ni se hicieron commits.

## Actualización y límites

El provider devuelve la entrada actual y 120 entradas futuras en límites de minuto. Usa política `.atEnd`, solicitando una nueva timeline al terminar el lote de unas dos horas. No contiene timers, tareas de animación ni ejecución continua.

Las fechas expresan actualizaciones deseadas, no garantizan un cambio puntual cada minuto: WidgetKit controla presupuestos, renderizado y recarga. Puede mostrar información atrasada si el sistema difiere la actualización. No promete segundos precisos ni la fluidez de la app principal. Se contemplan medianoche y los cambios de horario mediante fechas absolutas y el calendario actual.

Referencia: [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Personal Team y firma: resultado comprobado

Se comprobó en Xcode → Settings → Apple Accounts una cuenta **Personal Team**, con un dispositivo provisionado y un certificado existente. Un perfil local de iOS confirma Personal Team y el identificador `57PG39LTVS`; no es un perfil de extensión macOS. No se creó ni revocó ningún certificado y no se cambió la cuenta.

La sesión de terminal devolvió **0 identidades de firma válidas**. El intento de desarrollo con ese equipo falló en ambos targets:

```text
No signing certificate "Mac Development" found:
No "Mac Development" signing certificate matching team ID "57PG39LTVS"
with a private key was found.
```

Esto demuestra que esta sesión no puede completar la firma Mac con una clave disponible; no demuestra que todo Personal Team sea incompatible con WidgetKit. El widget solicita únicamente App Sandbox y no usa App Groups, CloudKit ni distribución. Apple permite pruebas personales mediante Xcode, con restricciones de cuenta; la combinación real de certificado/perfil debe ser validada por Xcode para los dos targets.

No se ha dado por válida una firma ad hoc para cargar el widget. La compilación de prueba sin firma verifica código y empaquetado, pero **no certifica que aparezca en Editar widgets**. La carga, el clic real y la firma de desarrollo siguen pendientes hasta resolver el certificado/clave desde Xcode.

Fuentes: [Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account), [capacidades macOS](https://developer.apple.com/help/account/reference/supported-capabilities-macos), [mismo equipo en cada target](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html).

## Ejecutar desde Xcode, paso a paso

1. Cierra cualquier instancia antigua de FLIP para evitar que macOS reutilice el proceso instalado. No borres ni sustituyas `/Applications/FLIP.app`.
2. Abre `~/Projects/FLIP/FLIP.xcodeproj`, **no** el proyecto de la carpeta iOS.
3. Xcode → Settings → Apple Accounts: selecciona tu cuenta y **Personal Team**. En **Manage Certificates**, comprueba que existe un certificado de desarrollo Apple/Mac con clave privada disponible en este Mac. Si Xcode indica que falta, resuélvelo tú desde ese panel; el agente no ha creado certificados. No compartas claves, contraseñas ni certificados en el chat.
4. En el navegador de proyecto, selecciona el proyecto FLIP → **TARGETS → FLIP → Signing & Capabilities**. Marca **Automatically manage signing** y selecciona tu **Personal Team**.
5. Repite lo mismo en **TARGETS → FLIPWidgets**. Ambos deben tener el mismo equipo. La extensión conserva **App Sandbox** activado. No añadas App Groups.
6. Mantén los identificadores `com.flip.aestheticclock` para la app y `com.flip.aestheticclock.widgets` para la extensión si Xcode los acepta. Si Xcode exige identificadores propios, cambia ambos de forma coordinada: la extensión debe empezar por el identificador de la app seguido de un punto. No cambies el target iOS. Un identificador distinto también crea un dominio de preferencias distinto para la app de prueba.
7. Selecciona esquema **FLIP-With-Widget**, destino **My Mac**, configuración de ejecución **Debug**, y pulsa **⌘R**. Espera a que la compilación, firma y ejecución terminen sin errores. No confundas un build con `CODE_SIGNING_ALLOWED=NO` con este paso.
8. La app ejecutada contiene `Contents/PlugIns/FLIPWidgets.appex`. Para identificarla, Xcode → Product → Show Build Folder in Finder → Products → Debug → FLIP.app. Es una copia de desarrollo; no la copies a Aplicaciones durante esta prueba.
9. Si Xcode muestra un error de firma/perfil para Personal Team, conserva el error exacto y no declares la carga verificada. No es necesario pagar o cambiar de membresía basándose solo en el fallo de terminal de esta sesión.

## Añadir el widget al escritorio

Después de ejecutar **la copia firmada de desarrollo** desde Xcode:

1. Haz clic derecho en una zona vacía del escritorio → **Editar widgets**.
2. Busca **FLIP** o selecciónalo en la lista de aplicaciones de la galería.
3. Añade la variante **pequeña** y después la **mediana** mediante el botón de añadir o arrastrándolas al escritorio.
4. Pulsa **Hecho**.
5. Comprueba que se ven hora/fecha y tarjetas negras/grises legibles. Observa que no aparecen segundos ni un temporizador.
6. Pulsa cada widget: debe abrir o activar la copia de FLIP. Comprueba que el reloj y el temporizador siguen funcionando.

Si FLIP no aparece, primero confirma que ⌘R ejecutó la copia correcta y que **FLIPWidgets** se firmó con el mismo equipo que FLIP. En el target FLIP, verifica **Build Phases → Embed App Extensions → FLIPWidgets.appex**. La extensión debe estar dentro del paquete. No reemplaces la aplicación instalada para intentar solucionar un error de firma.

En Xcode también puedes abrir `Sources/Widget/FLIPClockWidget.swift` → Editor → Canvas para los previews pequeños y medianos. Esos previews ayudan a revisar el diseño; no sustituyen la prueba de carga en el escritorio.

## Compilar y comprobar desde terminal

```sh
cd ~/Projects/FLIP
./Scripts/build-widget-preview.sh unsigned
./Scripts/test-widget.sh
./Scripts/test-countdown.sh
```

Salida separada: `build/MacWidgetPreview/FLIP.app`, con `Contents/PlugIns/FLIPWidgets.appex`. Es la compilación de verificación **sin firma de desarrollo**.

Cuando el certificado y la clave de Mac sean accesibles, el intento de firma de desarrollo puede repetirse sin tocar Aplicaciones:

```sh
FLIP_DEVELOPMENT_TEAM=57PG39LTVS ./Scripts/build-widget-preview.sh development
```

Salida de desarrollo: `build/MacWidgetDevelopment/FLIP.app`, únicamente si el comando termina correctamente. No se ha logrado una salida firmada válida en esta sesión. El script no solicita actualizaciones de aprovisionamiento ni crea certificados automáticamente.

## Verificaciones realizadas y pendientes

Realizadas:

- Compilación macOS con app y extensión, Release sin firma: correcta; extensión incrustada y ejecutable compatible con Apple Silicon.
- Compilación Debug sin firma: correcta, incluidos los previews tradicionales sin macros externas.
- iOS Simulator: compilación correcta, sin modificar su proyecto ni sus fuentes.
- Pruebas de timeline: 121 entradas ordenadas, cambio de fecha a medianoche y cambios de horario de Madrid en ambas direcciones.
- Validación del URL y rechazo de URLs ajenos o de temporizador.
- Renders fuera de pantalla pequeño/mediano y variantes compactas; revisión visual monocromática. PNG en `build/WidgetVerification/widget-*.png`. Son renders del diseño, no capturas de un widget cargado.
- Pruebas existentes de cuenta atrás y regresiones del reloj/fondos/favoritos: correctas.
- Integridad de iPhone, del código del reloj/temporizador y de la aplicación instalada: comprobada por hashes.
- Firma Personal Team intentada: bloqueada por ausencia de certificado Mac con clave privada accesible.

Pendientes:

- Firma de desarrollo válida para los dos targets.
- Registro/carga en la galería real de WidgetKit y adición al escritorio.
- Tamaños y accesibilidad bajo el host real, estilos de escritorio y distintos fondos de pantalla.
- Clic del widget abriendo la copia de desarrollo de FLIP y comportamiento al tener todas las ventanas cerradas.
- Observación de las actualizaciones reales, zona horaria, suspensión/despertar y presupuesto de WidgetKit.

Logs: `build/WidgetVerification/build-unsigned.log`, `build-development.log`, `build-debug.log`, `tests.log`, `ios-simulator.log`, `countdown-regression.log`, `clock-regression.log` e `integrity-report.txt`.
