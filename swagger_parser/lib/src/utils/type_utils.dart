import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang, [bool immutable = true]) {
    if (wrappingCollections.isEmpty) {
      return _questionMark(lang, immutable);
    }
    final sb = StringBuffer();
    for (final collection in wrappingCollections) {
      sb.write(collection.collectionsString);
    }
    sb.write(_questionMark(lang, immutable));
    for (final collection in wrappingCollections.reversed) {
      sb.write('>${collection.questionMark}');
    }

    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang, bool immutable) {
    var questionMark = (isRequired || wrappingCollections.isNotEmpty) && !nullable || defaultValue != null ? '' : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        final dartType = type.toDartType(format);
        if (!immutable) {
          if (dartType == "String") questionMark = "?";
          if (!type.isPrimitive) questionMark = "?";
        }

        return type.toDartType(format) +
            (!immutable && !type.isPrimitive && this.enumType == null ? "M" : "") +
            (dartType == 'dynamic' ? '' : questionMark);
      //
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }
}
