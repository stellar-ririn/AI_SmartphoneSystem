import 'dart:io';

void main() {
  print('Checking Android NDK configuration...');

  final groovyFile = File('android/app/build.gradle');
  final ktsFile = File('android/app/build.gradle.kts');

  if (groovyFile.existsSync()) {
    _fixGroovy(groovyFile);
  } else if (ktsFile.existsSync()) {
    _fixKts(ktsFile);
  } else {
    print('❌ Error: Could not find android/app/build.gradle or build.gradle.kts');
    print('   Please ensure you are in the root of the Flutter project and "android" folder exists.');
    exit(1);
  }
}

void _fixGroovy(File file) {
  print('Found Groovy build file: ${file.path}');
  String content = file.readAsStringSync();

  if (content.contains('ndkVersion')) {
    print('ℹ️  ndkVersion already present in build.gradle. Skipping.');
    return;
  }

  // Insert ndkVersion inside android { ... }
  // We look for "android {" and add the version immediately after.
  if (content.contains('android {')) {
    final newContent = content.replaceFirst(
      'android {',
      'android {\n    ndkVersion "27.0.12077973"'
    );
    file.writeAsStringSync(newContent);
    print('✅ Fixed NDK version in ${file.path}');
  } else {
    print('❌ Error: Could not find "android {" block in build.gradle');
  }
}

void _fixKts(File file) {
  print('Found Kotlin build file: ${file.path}');
  String content = file.readAsStringSync();

  if (content.contains('ndkVersion')) {
    print('ℹ️  ndkVersion already present in build.gradle.kts. Skipping.');
    return;
  }

  // Insert ndkVersion inside android { ... }
  if (content.contains('android {')) {
    final newContent = content.replaceFirst(
      'android {',
      'android {\n    ndkVersion = "27.0.12077973"'
    );
    file.writeAsStringSync(newContent);
    print('✅ Fixed NDK version in ${file.path}');
  } else {
    print('❌ Error: Could not find "android {" block in build.gradle.kts');
  }
}
