import 'dart:io';

Future<void> main() async {
  // Create the REAL pre-commit hook (not the bootstrapper)
  final hookContent = '''
#!/bin/sh

# Real pre-commit hook - only runs tests
REPO_ROOT="\$(git rev-parse --show-toplevel)"
cd "\$REPO_ROOT"

echo "🔍 Running pre-commit checks..."

# Run tests
echo "🧪 Running tests..."
flutter test
if [ \$? -ne 0 ]; then
  echo "❌ Tests failed. Fix failing tests."
  exit 1
fi

echo "✅ All pre-commit checks passed!"
''';

  final preCommitHook = File('.git/hooks/pre-commit');
  await preCommitHook.parent.create();
  await preCommitHook.writeAsString(hookContent);

  if (!Platform.isWindows) {
    await Process.run('chmod', ['a+x', preCommitHook.path]);
  }

  print("✅ Real pre-commit hooks installed!");
  print("🎯 Tests will run on every commit");
}
