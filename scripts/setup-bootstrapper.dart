import 'dart:io';

Future<void> main() async {
  // Copy the committed bootstrapper template to .git/hooks/
  final hookTemplate = File('hooks/pre-commit');
  final preCommitHook = File('.git/hooks/pre-commit');

  if (!hookTemplate.existsSync()) {
    print("❌ Hook template not found at hooks/pre-commit");
    print("💡 Make sure you've committed the hooks/ directory");
    exit(1);
  }

  await preCommitHook.parent.create();
  await preCommitHook.writeAsString(await hookTemplate.readAsString());

  if (!Platform.isWindows) {
    await Process.run('chmod', ['a+x', preCommitHook.path]);
  }

  print("✅ Bootstrapper hook installed!");
  print("🚀 On first commit, real hooks will auto-install");
}
