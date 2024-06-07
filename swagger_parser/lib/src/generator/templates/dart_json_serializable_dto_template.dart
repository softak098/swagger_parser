import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
  bool immutable = true,
}) {
  final className = dataClass.name.toPascal + (!immutable ? "M" : "");

  final cf = """
factory $className.from(${dataClass.name.toPascal} source)=>$className(
${_fieldMap(dataClass.parameters, "source")}
);
  """;

  final c = '''
${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  ${immutable ? "const" : ""} $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(
    dataClass.parameters,
  )}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
  ${_fieldsInClass(dataClass.parameters, immutable)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, dynamic> toJson() => _\$${className}ToJson(this);
  ${!immutable ? cf : ""}
}
''';

  if (immutable) {
    final h = '''
${generatedFileComment(
      markFileAsGenerated: markFileAsGenerated,
    )}${ioImport(dataClass)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';
''';

    return "$h$c";
  }
  return c;
}

String _fieldsInClass(List<UniversalType> parameters, bool immutable) => parameters
    .mapIndexed(
      (i, e) => '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '  ')}'
          '${_jsonKey(e)}  ${immutable ? "final" : ""} ${e.toSuitableType(ProgrammingLanguage.dart, immutable)} ${e.name};',
    )
    .join();

String _fieldMap(List<UniversalType> parameters, String source) {
  StringBuffer sb = StringBuffer();

  for (var e in parameters) {
    sb.write(e.name);
    sb.write(":");

    if (e.type.isPrimitive) {
      sb.write("$source.${e.name}");
    } else if (e.wrappingCollections.isEmpty) {
      var ex = "${e.type}M.from($source.${e.name}!)";
      sb.write(e.nullable ? "$source.${e.name}==null?null:$ex" : ex);
    }

    if (e.wrappingCollections.isNotEmpty) {
      sb.write(e.questionMark);
      sb.write(".map((e)=>${e.type}M.from(e)).toList()");
    } else {}

    sb.writeln(",");
  }

  return sb.toString();
}

String _parametersInConstructor(List<UniversalType> parameters) {
  final sortedByRequired = List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired.map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},').join();
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "  @JsonKey(name: '${protectJsonKey(t.jsonKey)}')\n";
}

/// return required if isRequired
String _required(UniversalType t) => t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(
            t.defaultValue,
            type: t.type,
          )}'
    : '';
