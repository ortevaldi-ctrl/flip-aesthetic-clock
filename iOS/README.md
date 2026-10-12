# FLIP para iPhone — reloj y temporizador

Versión iOS 0.2.0 (build 2), iPhone con iOS 17 o posterior. Proyecto independiente: `~/Projects/FLIP/iOS/FLIP-iOS.xcodeproj`, esquema `FLIP-iOS`. El proyecto macOS mantiene su target y versión 0.5.0. No se ha modificado ni reinstalado `/Applications/FLIP.app`.

## Temporizador de cuenta atrás — versión 0.2

El selector Reloj/Temporizador permite alternar sin detener la cuenta atrás. El temporizador reutiliza `FlipCard` y los 25 fondos existentes. Permite elegir 00–99 horas, 00–59 minutos y 00–59 segundos; una duración de cero no se puede iniciar. Iniciar crea una fecha de finalización; Pausar conserva la duración pendiente exacta, Reanudar calcula una nueva fecha y Reiniciar detiene la cuenta y devuelve la duración elegida, sin empezar automáticamente.

La pantalla adapta su composición a ambas orientaciones y respeta las zonas seguras. En el modo Temporizador, el selector y los controles no se ocultan. En horizontal, tarjetas y controles se distribuyen en dos columnas; el contenido puede desplazarse si el tamaño de texto requiere más espacio. Se conservan las tarjetas compartidas y su comportamiento Reducir movimiento. Al terminar aparece «Tiempo terminado», incluso si se está mirando el modo Reloj; estando la escena activa, se solicita un sonido del sistema, un aviso háptico y un anuncio de VoiceOver una sola vez.

La cuenta se guarda con su fecha final en UserDefaults del target iOS. No resta segundos acumulativamente. Al perder actividad se detiene la actualización de pantalla, manteniendo la fecha de finalización; al desbloquear o volver a la app se calcula de nuevo el tiempo restante. Una cuenta terminada mientras estaba bloqueado se muestra como terminada al volver, sin repetir el aviso sonoro de segundo plano.

### Notificaciones locales

«Avisar con el iPhone bloqueado» solicita autorización solo cuando el usuario activa el interruptor. No se solicita permiso al abrir la app, entrar en Temporizador o iniciar la cuenta con la opción desactivada. Sin permiso, el temporizador sigue funcionando y explica que el aviso requiere la app abierta y que el permiso se puede habilitar en Ajustes.

El aviso usa UserNotifications, sonido por defecto y una fecha UTC absoluta, redondeada al segundo siguiente para no sonar antes de finalizar. Se cancela al pausar, reiniciar, desactivar la opción o reconciliar una cuenta ya terminada; se programa de nuevo al reanudar. Solo se cancelan las solicitudes propias de FLIP. Una cola serial de reconciliación elimina solicitudes antiguas que pudieran completar su programación después de una pausa o un reinicio. Bloquear justo al vencer el plazo conserva el aviso ya programado. En primer plano se suprime el sonido duplicado de la notificación y se utiliza el aviso del temporizador.

La entrega y el sonido de una notificación dependen del permiso y de los ajustes del sistema, incluyendo Concentración y sonido. No hay servicios remotos, alarmas críticas ni ejecución continua artificial en segundo plano.

### Archivos de esta modificación

- `Countdown/CountdownState.swift`: máquina de estados Codable, fecha final, duración pausada y valores HH/MM/SS.
- `Countdown/CountdownController.swift`: publicación de tiempo restante, ciclo de escena, persistencia y finalización única; su timer solo refresca la proyección de la fecha.
- `Countdown/CountdownNotifications.swift`: autorización optativa y reconciliación serial, con cliente inyectable para pruebas.
- `Countdown/IOSCountdownServices.swift`: adaptador nativo UserNotifications, sonido AudioToolbox, háptica UIKit, VoiceOver y almacenamiento iOS.
- `Countdown/IOSCountdownView.swift`: tarjetas compartidas, selección de duración, controles y estado del permiso.
- `IOSClockScreen.swift`: selector de modo, integración del temporizador con la escena y aviso de finalización en modo Reloj.
- `FLIP-iOS.xcodeproj/project.pbxproj`: incluye únicamente estos archivos en iOS y actualiza su versión a 0.2.0/build 2. El target macOS no cambia.
- `../Scripts/build-ios.sh`: usa esquema y SDK explícitos, sin destino de ejecución, y DerivedData dentro del proyecto; corrige la ruta de caché del entorno restringido.
- `../Scripts/test-countdown.sh` y `../Tests/CountdownChecks.swift`: pruebas deterministas con fechas y cliente de notificaciones controlados.
- Este README: uso, compatibilidad, pruebas e instrucciones.

No se modificaron los archivos de `Sources/FLIP`, el proyecto macOS, su versión 0.5.0 ni `/Applications/FLIP.app`. Se verificaron sus hashes antes y después. No se hicieron commits.

### Verificaciones realizadas en esta sesión

- iOS Simulator Debug con SDK 26.5: **BUILD SUCCEEDED**. Esto verifica la compilación, no la ejecución en simulador.
- iPhoneOS Release con SDK 26.5, sin firma: **BUILD SUCCEEDED**. No se intentó instalar.
- macOS Release en `build/CountdownVerification/macOS`: compilación correcta.
- Regresión existente `Scripts/test.sh`: correcta para hora, controles, fondos, favoritos y pausa/resincronización macOS.
- `Scripts/test-countdown.sh`: pruebas correctas de HH/MM/SS, duración cero, pausa fraccionaria y prolongada, reanudación con nueva fecha, reinicio, finalización exacta y única, persistencia, vuelta desde segundo plano antes/después del plazo y bloqueo en el instante de finalización.
- Notificaciones probadas con un cliente simulado: ausencia de petición automática, petición al activar, permiso denegado, cancelación al pausar/reiniciar/desactivar, reprogramación al reanudar y protección contra programaciones asíncronas antiguas.
- Hashes del target y fuentes macOS, ejecutable y Info.plist instalados: idénticos antes/después.

Logs: `build/CountdownVerification/ios-simulator.log`, `ios-device.log`, `macos.log`, `mac-regression.log`, `countdown-tests.log`.

**Pendiente en entorno real:** ejecutar la interfaz iOS, observar ambas orientaciones y zonas seguras/Dynamic Island, Reducir movimiento y VoiceOver; comprobar sonido/háptica en el iPhone; aceptar/denegar el diálogo real; entrega de notificaciones con la app en segundo plano y teléfono bloqueado; confirmar que una pausa/reinicio no deja solicitudes reales. CoreSimulator devuelve errores de acceso/XPC en esta sesión y CoreDevice no pudo inicializarse. No se pudo enumerar ni comprobar el iPhone conectado. Los clientes simulados no verifican la entrega del sistema.

### Compatibilidad antes de instalar en el iPhone 14 Pro Max

El usuario indica iOS **27.0.1**. El Xcode instalado es **26.6 (17F113)** con SDK **iOS 26.5**; el mínimo del target continúa en iOS **17.0**. Compilar con un SDK anterior no basta para confirmar que ese Xcode podrá preparar, firmar y ejecutar en el teléfono con iOS 27.0.1.

La [tabla oficial de Apple](https://developer.apple.com/xcode/system-requirements/) muestra SDK iOS 26.5 para Xcode 26.6 y SDK iOS 27 para Xcode 27. Antes de instalar, conecta el teléfono y confirma en Xcode → Devices and Simulators y en el selector de destino que está disponible sin error de compatibilidad. Si Xcode no puede preparar esa versión, usa un Xcode compatible con iOS 27; no se ha actualizado Xcode ni intentado instalar en esta sesión.

### Cómo probar el temporizador

1. Abre `iOS/FLIP-iOS.xcodeproj`. Para simulador, selecciona `FLIP-iOS` y un iPhone 14 Pro Max con runtime instalado; ejecuta con ⌘R. Si falta el runtime, añádelo desde los componentes de Xcode. No hace falta firma para simulador.
2. En Temporizador, elige 00:00:15. Inicia; a los cinco segundos pausa. Espera otros diez: la duración pausada debe permanecer. Reanuda: debe terminar tras la duración pendiente, no inmediatamente.
3. Reinicia durante la cuenta y durante la pausa: debe regresar a la duración elegida y quedar detenido. Con 00:00:00, Iniciar debe estar deshabilitado. Prueba también 01:02:03.
4. Inicia diez segundos y alterna a Reloj: al terminar debe aparecer «Tiempo terminado». En primer plano debe emitir un único aviso. Regresa a Temporizador y comprueba 00:00:00; reinicia para quitar el estado terminado.
5. Rota el simulador en ambas direcciones. Repite con Reducir movimiento y texto grande. Comprueba que los controles siguen visibles y utilizables, y que las tarjetas no invaden las zonas seguras. El simulador no reproduce la háptica física.
6. Con la opción de avisos apagada, iniciar no debe pedir permiso. Actívala y deniega: debe mostrar la limitación y seguir contando. Habilita después el permiso en Ajustes para la segunda ronda.
7. Con permiso, inicia 15 segundos y ve a Inicio; vuelve antes del plazo para comprobar el tiempo restante, luego espera en segundo plano hasta finalizar. En dispositivo, repite bloqueando/desbloqueando. El aviso debe corresponder al plazo y la app debe mostrar terminado al volver.
8. Con permiso, inicia 20 segundos, pausa a los cinco y ve a Inicio: no debe llegar el aviso de la fecha original. Reanuda y ve a Inicio: debe llegar según la nueva fecha. Repite reiniciando y desactivando la opción: no debe llegar un aviso pendiente.
9. En iPhone físico, confirma primero la compatibilidad indicada arriba; usa Signing & Capabilities con tu Personal Team, selecciona el teléfono y ejecuta con ⌘R. Activa Modo de desarrollador y confianza solo si iOS/Xcode lo solicitan. No instales el paquete sin firma de `build/iOSDevice` directamente. Repite sonido, háptica, bloqueo y notificaciones en el dispositivo real.

Comandos de compilación y pruebas locales:

```sh
./Scripts/build-ios.sh simulator
./Scripts/build-ios.sh device
./Scripts/test-countdown.sh
```

Salidas iOS: `build/iOSSimulator/FLIP.app` y `build/iOSDevice/FLIP.app`; la segunda no está firmada. No se tocó la aplicación macOS instalada.

Referencias oficiales: [autorización de notificaciones](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications), [programación y cancelación local](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [compatibilidad Xcode](https://developer.apple.com/xcode/system-requirements/).

