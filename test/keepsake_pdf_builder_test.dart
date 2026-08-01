import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/data/models/models.dart';
import 'package:letters_to_heaven/features/keepsake/keepsake_pdf_builder.dart';

void main() {
  test('template preview builds for all book types', () async {
    final memorial = Memorial(
      id: 'm1',
      ownerUid: 'u1',
      displayName: 'Mom',
    );

    for (final bookType in KeepsakeBookType.values) {
      for (final theme in ExportTheme.values) {
        final doc = await KeepsakePdfBuilder(
          memorial: memorial,
          entries: const [],
          theme: theme,
          bookType: bookType,
          previewOnly: true,
        ).build();
        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      }
    }
  });
}
