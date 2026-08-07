# AI Background Remover — V2

This is a Flutter starter for an AI background-removal app.

## Current prototype
- Pick image from gallery or camera
- Real remove.bg API integration
- Transparent PNG result preview
- Save result to app storage
- Share result
- PRO screen at 3€ (Google Play Billing still needs store configuration)
- AdMob dependency included; ad placements/IDs still need configuration

## Important security note
Do not put a production remove.bg API key directly in a mobile app. For production, call remove.bg from your own backend/proxy so the secret is not exposed in the APK.

## Setup
1. Replace `PUT_YOUR_REMOVE_BG_API_KEY_HERE` during testing only.
2. Run `flutter pub get`.
3. Run `flutter run` or build an APK.
4. For production, move the API call to a backend and configure AdMob and Google Play Billing.
