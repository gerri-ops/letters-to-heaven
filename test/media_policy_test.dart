import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/media/media_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud storage defaults off and can be toggled', () async {
    SharedPreferences.setMockInitialValues({});
    final policy = MediaPolicy.instance;
    await policy.load();
    expect(policy.cloudStorageEnabled, isFalse);
    expect(policy.localOnlyNotice, contains('this device'));

    await policy.setCloudStorageEnabled(true);
    expect(policy.cloudStorageEnabled, isTrue);

    await policy.setCloudStorageEnabled(false);
    expect(policy.cloudStorageEnabled, isFalse);
  });
}
