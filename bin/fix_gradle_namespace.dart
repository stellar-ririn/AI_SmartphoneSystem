import 'dart:io';

void main() {
  print('Applying Gradle Namespace fix for Android...');

  final buildGradleFile = File('android/build.gradle');

  if (!buildGradleFile.existsSync()) {
    print('❌ Error: Could not find android/build.gradle');
    print('   Please ensure you are in the root of the Flutter project and "android" folder exists.');
    exit(1);
  }

  String content = buildGradleFile.readAsStringSync();

  // The fix script to inject
  const fixBlock = r'''
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                if (namespace == null) {
                    namespace project.group
                }
            }
        }
    }
}
''';

  if (content.contains('if (namespace == null)')) {
    print('ℹ️  Namespace fix already present in build.gradle. Skipping.');
    return;
  }

  // Append to the end of the file
  buildGradleFile.writeAsStringSync('\n' + fixBlock, mode: FileMode.append);
  print('✅ Added Namespace fix to android/build.gradle');
}
