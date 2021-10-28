import 'dart:isolate';

import 'package:analyzer_plugin/starter.dart';
import 'package:linting/analyzer_plugin.dart';
import 'package:stailer_linter_plugin_loader/rules.dart';

void main(List<String> args, SendPort sendPort) {
  ServerPluginStarter(LintingAnalyzerPlugin(
    rules: rules,
    analyzeCommand: AnalyzeCommand(const LintingAnalyzer()),
  )).start(sendPort);
}
