import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:custom_drift_annotations/annotations.dart';
import 'package:custom_drift_generator/src/model_visitor.dart';
import 'package:dartx/dartx.dart';
import 'package:source_gen/source_gen.dart';

class SyncGenerator extends GeneratorForAnnotation<SyncAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final ModelVisitor visitor = ModelVisitor();
    // Visit class fields and constructor
    element.visitChildren(visitor);

    // Buffer to write each part of generated class
    final buffer = StringBuffer();

    // Get the list of classes from the annotation
    final classes = annotation
        .read('classes')
        .listValue
        .map((e) => e.toTypeValue()?.element?.name)
        .toList();

    // Generate the sync function
    buffer.writeln(generateSyncFunction(
        visitor.className, classes.whereNotNull().toList()));

    // Generate the get changes function
    buffer.writeln(
        getChangesFunction(visitor.className, classes.whereNotNull().toList()));

    String generatedSyncedTablesCode = generateSyncedTablesCode(
        visitor.className, classes.whereNotNull().toList());
    buffer.writeln(generatedSyncedTablesCode);

    // Generate the combined streams function
    buffer.writeln(generateCombinedStreamsFunction(
        visitor.className, classes.whereNotNull().toList()));

    // Generate the RealtimeChannel extensions
    buffer.writeln(generateRealtimeChannelExtensions(
        visitor.className, classes.whereNotNull().toList()));

    // Generate the combined realtime channel extension
    buffer.writeln(generateCombinedRealtimeChannelExtension(
        visitor.className, classes.whereNotNull().toList()));

    return buffer.toString();
  }

  // Method to generate the sync function
  String generateSyncFunction(String className, List<String> classes) {
    final buffer = StringBuffer();

    buffer.writeln('// Sync function');
    buffer.writeln(
        'Future<void> _\$${className}Sync(Map<String, dynamic> changes, AppDatabase db) async {');
    buffer.writeln('  await Future.wait([');
    for (final className in classes) {
      buffer.writeln('    ${className}SyncExtension.sync(changes, db),');
    }
    buffer.writeln('  ]);');
    buffer.writeln('}');

    return buffer.toString();
  }

  // Method to generate the get changes function
  String getChangesFunction(String className, List<String> classes) {
    final buffer = StringBuffer();

    buffer.writeln('// get changes function');
    buffer.writeln(
        'Future<Map<String, dynamic>> _\$${className}GetChanges(DateTime lastSyncedAt, AppDatabase db, String currentInstanceId) async {');
    buffer.writeln('final res = await Future.wait([');
    for (final className in classes) {
      buffer.writeln(
          '    ${className}GetChangesExtension.getChanges(lastSyncedAt, db, currentInstanceId),');
    }
    buffer.writeln('  ]);');
    buffer
        .writeln('return res.fold<Map<String, dynamic>>({}, (prev, element) {');
    buffer.writeln('  prev.addAll(element);');
    buffer.writeln('  return prev;');
    buffer.writeln('});');
    buffer.writeln('}');

    return buffer.toString();
  }

  // Method to generate synced tables code
  String generateSyncedTablesCode(String className, List<String> classes) {
    final buffer = StringBuffer();

    buffer.writeln('List<String> _\$${className}SyncedTables() {');
    buffer.writeln('  return [');
    for (final className in classes) {
      buffer.writeln('    $className.serverTableName,');
    }
    buffer.writeln('  ];');
    buffer.writeln('}');

    return buffer.toString();
  }

  // Method to generate combined streams function
  String generateCombinedStreamsFunction(
      String className, List<String> classes) {
    final buffer = StringBuffer();

    buffer.writeln('// Combined streams function');
    buffer.writeln(
        'Stream<List<dynamic>> _\$${className}CombinedStreams(AppDatabase db) {');
    for (final className in classes) {
      final lowerClassName = className.toLowerCase();
      buffer.writeln(
          '  final ${lowerClassName}Stream = (db.select(db.$lowerClassName)..where((tbl) => tbl.isRemote.equals(false))).watch();');
    }
    buffer.writeln();
    buffer.writeln('  // Combine N streams');
    buffer.writeln('  return Rx.combineLatestList([');
    for (final className in classes) {
      final lowerClassName = className.toLowerCase();
      buffer.writeln('    ${lowerClassName}Stream,');
    }
    buffer.writeln('  ]);');
    buffer.writeln('}');

    return buffer.toString();
  }

  String generateCombinedRealtimeChannelExtension(
      String className, List<String> classes) {
    final buffer = StringBuffer();

    buffer.writeln(
        'extension Combined${className}RealtimeChannelExtension on RealtimeChannel {');
    buffer.writeln(
        '  RealtimeChannel onAll${className}Changes(String currentInstanceId, void Function(PostgresChangePayload payload) callback) {');

    buffer.writeln('    return');
    for (int i = 0; i < classes.length; i++) {
      final className = classes[i];

      buffer.writeln(
          '      ${i == 0 ? "this." : ""}on${className}Changes(currentInstanceId, callback)${i < classes.length - 1 ? '.' : ';'}');
    }
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  // Method to generate RealtimeChannel extensions
  String generateRealtimeChannelExtensions(
      String className, List<String> classes) {
    final buffer = StringBuffer();

    for (final className in classes) {
      final lowerClassName = className.toLowerCase();
      final schemaTable = '$className.serverTableName'.split('.');

      buffer.writeln(
          'extension ${className}RealtimeChannelExtension on RealtimeChannel {');
      buffer.writeln(
          '  RealtimeChannel on${className}Changes(String currentInstanceId, void Function(PostgresChangePayload payload) callback) {');
      buffer.writeln('    return this.onPostgresChanges(');
      buffer.writeln('      event: PostgresChangeEvent.all,');
      buffer
          .writeln('      schema: $className.serverTableName.split(\'.\')[0],');
      buffer
          .writeln('      table: $className.serverTableName.split(\'.\')[1],');
      buffer.writeln('      filter: PostgresChangeFilter(');
      buffer.writeln('        type: PostgresChangeFilterType.neq,');
      buffer.writeln('        column: \'instance_id\',');
      buffer.writeln('        value: currentInstanceId,');
      buffer.writeln('      ),');
      buffer.writeln('      callback: callback,');
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln('}');
    }

    return buffer.toString();
  }
}
