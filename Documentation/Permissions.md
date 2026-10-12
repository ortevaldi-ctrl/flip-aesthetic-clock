# Permisos y privacidad de FLIP

## Permisos concedidos

### macOS

- **App Sandbox:** activado para la aplicación principal y el widget.
- **Notificaciones locales:** se usan únicamente para avisar cuando termina una cuenta atrás y el usuario activa esa opción.
- **Esquema URL `flip-clock://`:** permite que el widget abra la aplicación. No concede acceso a datos del sistema.

La aplicación no solicita acceso a red, cámara, micrófono, ubicación, contactos, calendario, fotos, iCloud, App Groups ni llavero.

### iOS

- **Notificaciones locales:** se solicitan solo al activar «Avisar con el iPhone bloqueado».
- **Vibración y VoiceOver:** son APIs del sistema y no requieren permisos del usuario.

La aplicación no solicita acceso a red, cámara, micrófono, ubicación, contactos, calendario, fotos, iCloud ni Bluetooth.

## Condiciones de funcionamiento

- La cuenta atrás funciona sin conceder permisos de notificación.
- Si el usuario deniega las notificaciones, el temporizador sigue funcionando mientras la aplicación está abierta.
- Las notificaciones pueden verse afectadas por los ajustes del sistema, concentración, sonido y permisos revocados.
- Los datos del reloj, preferencias, favoritos y cuenta atrás se guardan localmente.
- FLIP no envía datos a servidores ni depende de conexión a Internet.
- El widget solo muestra la hora y la fecha del sistema y abre FLIP mediante el esquema URL registrado.
