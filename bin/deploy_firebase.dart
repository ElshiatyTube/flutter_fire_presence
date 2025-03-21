import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print("❌ Error: Please provide an API URL to mirror.");
    print("Usage: dart bin/deploy_firebase.dart <API_URL>");
    exit(1);
  }

  final apiUrl = args[0];
  final functionsDir = 'firebase/functions';
  final customIndexPath = 'bin/index.js'; // Path to your custom index.js

  // Step 1: Initialize Firebase Functions (if not already initialized)
  if (!Directory('$functionsDir/node_modules').existsSync()) {
    print("🚀 Initializing Firebase Functions...");
    final initProcess = await Process.run(
      'firebase',
      ['init', 'functions', '--force'],
      workingDirectory: functionsDir,
      runInShell: true,
    );

    if (initProcess.exitCode != 0) {
      print("❌ Failed to initialize Firebase Functions: ${initProcess.stderr}");
      exit(initProcess.exitCode);
    }

    print("✅ Firebase Functions initialized successfully!\n");
  }

  // Step 2: Replace index.js with the custom version (if exists)
  final indexPath = '$functionsDir/index.js';
  if (File(customIndexPath).existsSync()) {
    print("🔄 Replacing $indexPath with the custom index.js...");
    try {
      File(customIndexPath).copySync(indexPath);
      print("✅ index.js replaced successfully!\n");
    } catch (e) {
      print("❌ Failed to replace index.js: $e");
      exit(1);
    }
  } else {
    print("⚠️ Custom index.js not found at $customIndexPath. Skipping replacement.");
  }

  // Step 3: Install axios (if not already installed)
  print("🚀 Checking and installing axios in $functionsDir...");
  final installAxios = await Process.run(
    'npm',
    ['install', 'axios'],
    workingDirectory: functionsDir,
    runInShell: true,
  );

  if (installAxios.exitCode != 0) {
    print("❌ Failed to install axios: ${installAxios.stderr}");
    exit(installAxios.exitCode);
  }

  print("✅ Axios installed successfully!\n");

  // Step 4: Set Firebase function config
  print("🔄 Setting Firebase function config: API_MIRROR_URL = $apiUrl");

  final setConfig = await Process.run(
    'firebase',
    ['functions:config:set', 'api.mirror_url=$apiUrl'],
    workingDirectory: functionsDir,
    runInShell: true,
  );

  if (setConfig.exitCode != 0) {
    print("❌ Failed to set Firebase config: ${setConfig.stderr}");
    exit(setConfig.exitCode);
  }

  print("✅ Firebase config set successfully!\n");

  // Step 5: Deploy only the onUserPresenceStatusChange function
  print("🚀 Deploying Firebase function: onUserPresenceStatusChange...");
  final deployProcess = await Process.start(
    'firebase',
    ['deploy', '--only', 'functions:onUserPresenceStatusChange'],
    workingDirectory: functionsDir,
    runInShell: true,
  );

  deployProcess.stdout.transform(SystemEncoding().decoder).listen((data) {
    stdout.write(data);
  });

  deployProcess.stderr.transform(SystemEncoding().decoder).listen((data) {
    stderr.write(data);
  });

  final exitCode = await deployProcess.exitCode;
  if (exitCode == 0) {
    print("\n✅ Firebase function 'onUserPresenceStatusChange' deployed successfully!");
  } else {
    print("\n❌ Deployment failed with exit code: $exitCode");
  }
}
