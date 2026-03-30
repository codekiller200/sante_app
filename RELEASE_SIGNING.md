# Signature Release Android

## 1. Generer une keystore

Sous Windows :

```bash
keytool -genkey -v -keystore C:\Users\hp\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Choisis et conserve :
- `storePassword`
- `keyPassword`
- `keyAlias`

## 2. Creer le fichier de config

Copie [key.properties.example](/C:/Users/hp/Desktop/sante_app/android/key.properties.example) vers `android/key.properties` puis remplace les valeurs :

```properties
storePassword=TON_MOT_DE_PASSE_KEYSTORE
keyPassword=TON_MOT_DE_PASSE_CLE
keyAlias=upload
storeFile=C:\\Users\\hp\\upload-keystore.jks
```

## 3. Build release

APK :

```bash
flutter clean
flutter pub get
flutter build apk --release
```

App Bundle Play Store :

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## Notes

- Tant que `android/key.properties` n existe pas, le projet continue a utiliser la signature debug.
- `android/key.properties`, `*.jks` et `*.keystore` sont ignores par Git.
- Pour le Play Store, prefere `flutter build appbundle --release`.
