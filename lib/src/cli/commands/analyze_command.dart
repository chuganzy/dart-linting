import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import '../../../foundation.dart';
import '../analyze_reporter.dart';
import 'models/base_command.dart';
import 'models/common_command_options.dart';
import 'models/invalid_argument_exception.dart';

const String _reporter = 'reporter';

class _CommandRequest {
  final AnalysisOptions _analysisOptions;
  final ArgResults _argResults;
  final Iterable<AnalyzeReporter> _reporters;
  final Iterable<Rule> _rules;
  final String? _optionKey;

  _CommandRequest(
    this._analysisOptions,
    this._argResults,
    this._reporters,
    this._rules,
    this._optionKey,
  );

  Iterable<Rule> get rules {
    return _rules.where((rule) =>
        _analysisOptions.lintingRules(_optionKey).contains(rule.ruleId));
  }

  Iterable<AnalyzeReporter> get reporters {
    return _reporters
        .where((reporter) => reporter.reporterId == _argResults[_reporter]);
  }

  Iterable<String> get rest {
    return _argResults.rest;
  }

  String get rootFolder {
    return _argResults[CommonCommandOptions.rootFolder];
  }

  Iterable<String> get excludes {
    return _analysisOptions.analyzerExclude.toList()
      ..add(_argResults[CommonCommandOptions.exclude]);
  }

  Future<void> validate() async {
    if (rules.isEmpty) {
      throw InvalidArgumentException('The executable rules is empty.');
    }
    if (reporters.isEmpty) {
      throw InvalidArgumentException(
        "Can't find ${_argResults[_reporter]} reporter from reporters",
      );
    }
  }
}

class AnalyzeCommand extends BaseCommand<_CommandRequest> {
  final Iterable<Rule> rules;
  final Iterable<AnalyzeReporter> reporters;
  final LintingAnalyzer analyzer;
  final String? optionKey;

  @override
  String get description => 'Collect rules violations';

  @override
  String get name => 'analyze';

  @override
  String get invocation =>
      '${runner!.executableName} $name [arguments] <directories>';

  AnalyzeCommand({
    required this.rules,
    required this.reporters,
    required this.analyzer,
    this.optionKey,
  }) {
    if (rules.isEmpty) {
      throw Exception("rule is empty!");
    }
    if (reporters.isEmpty) {
      throw Exception("reporters is empty!");
    }
    _addFlags();
  }

  @override
  Future<_CommandRequest> validateCommand() async {
    validateRootFolderOption();
    validateTargetDirectories();

    final request = _CommandRequest(
      await _loadAnalysisOptions(optionKey),
      argResults!,
      reporters,
      rules,
      optionKey,
    );
    request.validate();
    return request;
  }

  @override
  Future<void> runCommand(_CommandRequest request) async {
    final foldersToAnalyze = request.rest;
    final rootFolder = request.rootFolder;
    final rules = request.rules;
    final excludes = request.excludes;
    final reporter = request.reporters.first;

    final resultList = <AnalyzedResult>[];
    for (final dirname in foldersToAnalyze) {
      final directory = Directory(dirname);
      final files = directory.listSync(recursive: true);

      for (final file in files) {
        final result = await _analyze(
          AnalyzerConfig(
            rules: rules,
            excludes: excludes,
            rootFolder: rootFolder,
          ),
          analyzer,
          file,
        );
        resultList.add(result);
      }
    }

    reporter.report(resultList);
  }

  Future<AnalyzedResult> _analyze(
    AnalyzerConfig config,
    LintingAnalyzer analyzer,
    FileSystemEntity file,
  ) async {
    final filePath = file.path;
    final resolvedUnitResult = await FileResolver.resolve(filePath);
    return await analyzer.analyze(
      config,
      resolvedUnitResult,
      filePath: filePath,
    );
  }

  void _addFlags() {
    _usesReporterOption();
    usesRootFolderOption();
    usesExcludeOption();
  }

  void _usesReporterOption() {
    argParser
      ..addSeparator('')
      ..addOption(
        _reporter,
        abbr: 'r',
        help: 'The format of the output of the analysis.',
        valueHelp: reporters.first.reporterId,
        allowed: reporters.map((reporter) => reporter.reporterId),
        defaultsTo: reporters.first.reporterId,
      );
  }

  Future<AnalysisOptions> _loadAnalysisOptions(String? optionKey) async {
    final analysisOptionsFile = File(join(
      argResults![CommonCommandOptions.rootFolder],
      'analysis_options.yaml',
    ));
    if (!analysisOptionsFile.existsSync()) {
      throw Exception("Can't find $analysisOptionsFile");
    }

    final analysisOptions = AnalysisOptionsLoader().loadFromFile(
      analysisOptionsFile,
    );
    if (analysisOptions.lintingRules(optionKey).isEmpty) {
      throw Exception('linting.rules is empty on $analysisOptionsFile');
    }

    return analysisOptions;
  }
}
