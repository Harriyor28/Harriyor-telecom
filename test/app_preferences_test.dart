import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harryyor_telecom_tools/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favorites and settings persist correctly', () async {
    SharedPreferences.setMockInitialValues({});

    await AppPreferences.setFavoriteUssdCodes({'*310#', '*323#'});
    final favorites = await AppPreferences.getFavoriteUssdCodes();
    expect(favorites, contains('*310#'));
    expect(favorites, contains('*323#'));

    await AppPreferences.setPreferredNetwork('Airtel');
    expect(await AppPreferences.getPreferredNetwork(), 'Airtel');

    await AppPreferences.setDarkMode(true);
    expect(await AppPreferences.getDarkMode(), isTrue);
  });
}
