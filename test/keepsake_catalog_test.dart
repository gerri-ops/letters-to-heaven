import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/features/keepsake/keepsake_catalog.dart';

void main() {
  test('keepsake catalog covers book types and three export styles', () {
    expect(KeepsakeBookType.values, hasLength(8));
    expect(ExportTheme.values, hasLength(3));
    expect(ExportTheme.journalPdf.label, 'Journal PDF');
    expect(ExportTheme.simple.label, 'Simple');
    expect(ExportTheme.inkSaver.label, 'Ink Saver');
    expect(
      ExportThemeX.fromLegacyName('cardinalGarden'),
      ExportTheme.journalPdf,
    );
    expect(ExportThemeX.fromLegacyName('softNeutral'), ExportTheme.simple);
    expect(
      ExportThemeX.fromLegacyName('inkSavingSimple'),
      ExportTheme.inkSaver,
    );
    expect(
      KeepsakePreviewCopy.headline,
      contains('keepsake you can hold'),
    );
    expect(
      KeepsakePreviewCopy.supporting,
      contains('Journal PDF, Simple, and Ink Saver'),
    );
    expect(KeepsakePreviewCopy.stylesLine, 'Journal PDF · Simple · Ink Saver');
  });
}
