import 'dart:io';

import 'package:linting/src/analysis_options_loader/analysis_options_loader.dart';
import 'package:test/test.dart';

void main() {
  group('loadFromFile', () {
    test('has yaml', () async {
      final options =
          await AnalysisOptionsLoader().loadFromFile(File("analysis_options.yaml"));
      expect(options.options["include"], "package:lints/recommended.yaml");
    });

    test('no yaml', () async {
      final options = await AnalysisOptionsLoader()
          .loadFromFile(File("analysis_options_not_found.yaml"));
      expect(options.options["include"], null);
    });

    test('null', () async {
      final options = await AnalysisOptionsLoader().loadFromFile(null);
      expect(options.options["include"], null);
    });
  });
}