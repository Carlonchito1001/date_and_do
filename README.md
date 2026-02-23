# 📱 Date & Do – App Android

Aplicación móvil desarrollada en Flutter para el proyecto Date & Do.

Actualmente está configurada solo para Android :v .

# 🚀 Cómo levantar el proyecto

## 1️⃣ Requisitos

Antes de empezar necesitas:

- Tener Flutter instalado (versión estable recomendada)
- Tener Android Studio instalado
- Tener un emulador Android o un celular físico conectado
- Tener configurado el SDK de Android

Para verificar que todo está bien:

```bash
flutter doctor
```

Si todo está correcto, continuamos.

## Instalar Dependencias

```bash
flutter pub get
```

Esto descargará todas las dependencias necesarias.

## Ejecutar la aplicación

```bash
flutter run
```

Si todo está correcto, la app debería iniciar sin problemas.

## 🔧 Configuración importante

La Url esat configurada en:

```bash
lib/api/api_endpoints.dart
```

Si deseas cambiar a un entorno de pruebas (DEV), debes modificar esa URL.

## 🔐 Autenticación

La app usa:

- Firebase Authentication
- Google Sign In
- Tokens JWT del backend

Los tokens se guardan en:

```bash
SharedPreferences
```

## 🔔 Notificaciones Push (Firebase)

La app usa:

- Firebase Core
- Firebase Messaging
- Flutter Local Notifications

Es obligatorio que el proyecto tenga:

```bash
android/app/google-services.json
```

Si no está configurado, la app no recibirá notificaciones.

## 📍 Permisos que usa la app

En Android:

- Ubicación (GPS)
- Internet
- Notificaciones (Android 13+)

Estos permisos están definidos en:

```bash
android/app/src/main/AndroidManifest.xml
```

## ⚠️ Consideraciones importantes

✔ Esta app solo está configurada para Android
✔ No tiene configuración para iOS
✔ Si cambias el backend debes revisar los endpoints
✔ Si cambias la estructura del JSON del backend, debes actualizar los modelos
✔ La ubicación es necesaria para algunas funciones
✔ Firebase debe estar correctamente configurado

## 📦 Generar APK

Para generar el APK:

```bash
flutter build apk --release
```

El archivo se genera en:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

## 👨‍💻 Proyecto desarrollado con

Flutter

Dart

Firebase

Backend Django

API REST propi
