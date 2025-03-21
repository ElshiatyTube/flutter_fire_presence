# Firebase Presence Handler

## Overview
This package offers a robust Firebase-based presence detection system using Dart and Firebase Realtime Database. It accurately tracks user connectivity status and updates their presence in real time, ensuring reliability even in critical scenarios such as network disconnections, app crashes, device shutdowns, or user logouts. Additionally, it provides the flexibility to mirror this real-time online status to your own database via a custom API, ensuring seamless integration with your backend.

## Features
- Monitors internet connectivity using `connectivity_plus`.
- Updates Firebase Realtime Database with user presence status.
- Automatically handles `onDisconnect` to update offline status.
- Provides a `Stream<bool>` to listen for connectivity changes.
- Ability to Deploys a Firebase Cloud Function to mirror presence data to your database via an API.

## Installation

Add dependencies to your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_fire_presence: ^X.X.X  # Replace with the latest version
```

## Usage

### Start Monitoring Connection where needed (for example when the app starts or when the user logs in):
```dart
FirePresenceHandler().connect(uid: 'user_id');
```

### Force Disconnect when needed (for example when the user logs out):
```dart
FirePresenceHandler().forceDisconnect(uid: 'user_id');
```

## Firebase Realtime Database Setup
Ensure you have setup your Firebase project and configured the Realtime Database 

## Firebase Cloud Functions Deployment

### Prerequisites

1. Install Firebase CLI: [Firebase CLI](https://firebase.google.com/docs/cli)
2. Login to Firebase:
   ```sh
   firebase login
   ```
3. Create a `firebase` folder in the root of your project and open it in the terminal:
   ```sh
   mkdir firebase && cd firebase
   ```
4. Initialize Firebase Functions:
   ```sh
   firebase init functions
   ```
    - Select your Firebase project.
    - Choose **JavaScript** as the language.
    - Choose **No** if asked about TypeScript.
    - Choose **No** when asked about enabling ESLint setup.

### Deploy Firebase Functions

Run the deployment script from the root of your project:

```sh
dart bin/deploy_firebase.dart <API_URL>
```

Replace `<API_URL>` with the actual API where presence data should be mirrored.

## API Payload Example

The API will receive presence data in the following JSON format:
```json
{
  "uid": "user_id",
  "online": true,
  "lastOnline": 1630000000000
}
```
## Firebase Function Logic

The function `onUserPresenceStatusChange` listens for presence updates and sends the data to an external API:

```js
exports.onUserPresenceStatusChange = functions.database
  .ref('/presence/{uId}')
  .onWrite((change, context) => {
    const data = change.after.val();
    if (!data) return null;
    
    const apiUrl = process.env.API_MIRROR_URL;
    if (!apiUrl) return null;
    
    return axios.post(apiUrl, {
      uid: context.params.uId,
      online: data.online ?? false,
      lastOnline: data.lastOnline,
    });
  });
```

## Cleanup and Disposal

Dispose of the connection when no longer needed:

```dart
firePresenceHandler.dispose();
```

## License

This project is licensed under the MIT License. Feel free to modify and use it in your applications.

---

**Author:** Youssef Elshiaty
