import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:custom_drift_annotations/annotations.dart';
import 'package:custom_drift_generator/src/model_visitor.dart';
import 'package:source_gen/source_gen.dart';

class ClassSyncCodeGenerator extends GeneratorForAnnotation<CustomAnnotation> {
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

    String generatedSyncCode = generateSyncCode(visitor.className);
    buffer.writeln(generatedSyncCode);

    String generatedGetChangesCode = generateGetChangesCode(visitor.className);
    buffer.writeln(generatedGetChangesCode);

    return buffer.toString();
  }

  // Method to generate task sync code
  String generateSyncCode(String className) {
    final buffer = StringBuffer();
    final lowerClassName = className.toLowerCase();

    buffer.writeln("extension ${className}SyncExtension on $className {");
    buffer.writeln('// $className sync code');
    buffer.writeln(
        'static Future<void> sync(Map<String, dynamic> changes, AppDatabase db) async {');
    buffer.writeln(
        '   final ${lowerClassName}Changes = changes[$className.serverTableName] as Map<String, dynamic>;');
    buffer.writeln('    final ${lowerClassName}Instance = db.$lowerClassName;');
    buffer.writeln(
        '   final createdOrUpdated = ${lowerClassName}Changes[\'created\'] + ${lowerClassName}Changes[\'updated\'];');
    buffer.writeln('  for (final record in createdOrUpdated) {');
    buffer.writeln(
        '     final existingRecord = await (db.select(${lowerClassName}Instance)');
    buffer.writeln(
        '            ..where((tbl) => tbl.id.equals(record[\'id\'])))');
    buffer.writeln('          .getSingleOrNull();');
    buffer.writeln('      if (existingRecord == null ||');
    buffer.writeln('          DateTime.parse(record[\'updated_at\'])');
    buffer.writeln('              .isAfter(existingRecord.updatedAt)) {');
    buffer.writeln('        await db');
    buffer.writeln('            .into(${lowerClassName}Instance)');
    buffer.writeln(
        '           .insertOnConflictUpdate(${className}Data.fromJson((record as Map<String, dynamic>)..addAll({\'isRemote\': true})));');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');

    return buffer.toString();
  }

  // Method to generate getChanges code
  // Method to generate getChanges code
  String generateGetChangesCode(String className) {
    final buffer = StringBuffer();
    final lowerClassName = className.toLowerCase();

    buffer.writeln("extension ${className}GetChangesExtension on $className {");
    buffer.writeln('// $className getChanges code');
    buffer.writeln(
        'static Future<Map<String, Map<String, List<dynamic>>>> getChanges(DateTime lastSyncedAt, AppDatabase database, String currentInstanceId) async {');
    buffer.writeln(
        '  final ${lowerClassName}Instance = database.$lowerClassName;');
    buffer.writeln(
        '  final created = await (database.select(${lowerClassName}Instance)');
    buffer.writeln(
        '        ..where((tbl) => tbl.createdAt.isBiggerOrEqualValue(lastSyncedAt) & tbl.isRemote.equals(false)))');
    buffer.writeln('      .get();');
    buffer.writeln(
        '  final updated = await (database.select(${lowerClassName}Instance)');
    buffer.writeln(
        '        ..where((tbl) => tbl.updatedAt.isBiggerOrEqualValue(lastSyncedAt) & tbl.createdAt.isSmallerThanValue(lastSyncedAt) & tbl.isRemote.equals(false)))');
    buffer.writeln('      .get();');
    buffer.writeln(
        '  final deleted = await (database.select(${lowerClassName}Instance)');
    buffer.writeln(
        '        ..where((tbl) => tbl.deletedAt.isBiggerOrEqualValue(lastSyncedAt) & tbl.isRemote.equals(false)))');
    buffer.writeln('      .get();');
    buffer.writeln('  return {');
    buffer.writeln('    $className.serverTableName: {');
    buffer.writeln(
        '      \'created\': created.map((e) => e.toJson()..remove(\'isRemote\')..addAll({');
    buffer.writeln('        \'instance_id\': currentInstanceId,');
    buffer.writeln('      })).toList(),');
    buffer.writeln(
        '      \'updated\': updated.map((e) => e.toJson()..remove(\'isRemote\')..addAll({');
    buffer.writeln('        \'instance_id\': currentInstanceId,');
    buffer.writeln('      })).toList(),');
    buffer.writeln(
        '      \'deleted\': deleted.map((e) => e.toJson()..remove(\'isRemote\')..addAll({');
    buffer.writeln('        \'instance_id\': currentInstanceId,');
    buffer.writeln('      })).toList(),');
    buffer.writeln('    }');
    buffer.writeln('  };');
    buffer.writeln('}');
    buffer.writeln('}');

    return buffer.toString();
  }
}
