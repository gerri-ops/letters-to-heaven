import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/features/keepsake/keepsake_catalog.dart';

void main() {
  test('keepsake catalog covers book types and styles', () {
    expect(KeepsakeBookType.values, hasLength(8));
    expect(ExportTheme.values, hasLength(3));
    expect(ExportTheme.cardinalGarden.label, 'Cardinal Garden');
    expect(ExportTheme.softNeutral.label, 'Soft Neutral');
    expect(ExportTheme.inkSavingSimple.label, 'Ink-Saving Simple');
    expect(
      KeepsakePreviewCopy.headline,
      'You have already begun a keepsake.',
    );
    expect(
      KeepsakePreviewCopy.supporting,
      contains('clearest reason Premium exists'),
    );
  });
}
