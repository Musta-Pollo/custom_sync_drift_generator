library custom_sync_drift_generator;

import 'package:build/build.dart';
import 'package:custom_sync_drift_generator/src/json_generator.dart';
import 'package:custom_sync_drift_generator/src/sync_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:pub_semver/pub_semver.dart';

Builder generateClassSyncCode(BuilderOptions options) {
  // Step 1
  return PartBuilder(
    [ClassSyncCodeGenerator()], // Step 2
    formatOutput:
        options.config['format'] == false ? identityFormatter : noOpFormatter,

    '.classsync.dart',
    header: '''
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
    ''',
    options: options,
  );
}

// Define the identity formatter
String Function(String, Version) identityFormatter =
    (String str, Version version) => str;
String Function(String, Version) noOpFormatter =
    (String str, Version version) => str;

Builder generateSyncCode(BuilderOptions options) {
  // Step 1
  return PartBuilder(
    [SyncGenerator()], // Step 2
    formatOutput:
        options.config['format'] == false ? identityFormatter : noOpFormatter,

    '.sync.dart',
    header: '''
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
    ''',
    options: options,
  );
}
