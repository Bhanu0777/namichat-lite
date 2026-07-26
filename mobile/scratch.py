import re

with open('test/widget/features/settings/settings_page_test.dart', 'r') as f:
    content = f.read()

helper = '''
Future<void> pumpSettingsPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_buildSettingsPage());
  await tester.pumpAndSettle();
}
'''

content = content.replace('void main() {', helper + '\nvoid main() {')

# Remove the setup in the first test
first_test_pattern = r'''    testWidgets\('renders all five section headers', \(tester\) async \{
      tester\.view\.physicalSize = const Size\(800, 2000\);
      tester\.view\.devicePixelRatio = 1\.0;
      addTearDown\(\(\) \{
        tester\.view\.resetPhysicalSize\(\);
        tester\.view\.resetDevicePixelRatio\(\);
      \}\);
      await tester\.pumpWidget\(_buildSettingsPage\(\)\);
      await tester\.pumpAndSettle\(\);'''

first_test_replacement = '''    testWidgets('renders all five section headers', (tester) async {
      await pumpSettingsPage(tester);'''

content = re.sub(first_test_pattern, first_test_replacement, content)

# Replace all other instances
old_pump = r'''      await tester\.pumpWidget\(_buildSettingsPage\(\)\);
      await tester\.pumpAndSettle\(\);'''
new_pump = '''      await pumpSettingsPage(tester);'''

content = re.sub(old_pump, new_pump, content)

with open('test/widget/features/settings/settings_page_test.dart', 'w') as f:
    f.write(content)
