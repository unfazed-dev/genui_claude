/// Extracts searchable keywords from widget schemas and metadata.
///
/// This utility tokenizes names, parses descriptions, and extracts
/// relevant terms from JSON schemas for building searchable indexes.
class KeywordExtractor {
  /// Creates a keyword extractor.
  KeywordExtractor();

  /// Common English stop words to filter out.
  static const Set<String> stopWords = {
    // Articles
    'a', 'an', 'the',
    // Pronouns
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves',
    'you', 'your', 'yours', 'yourself', 'yourselves',
    'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself',
    'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
    'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those',
    // Verbs (common)
    'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing',
    'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall',
    'can', 'need', 'dare', 'ought', 'used',
    // Prepositions
    'about', 'above', 'across', 'after', 'against', 'along', 'among',
    'around', 'at', 'before', 'behind', 'below', 'beneath', 'beside',
    'between', 'beyond', 'by', 'down', 'during', 'except', 'for', 'from',
    'in', 'inside', 'into', 'like', 'near', 'of', 'off', 'on', 'onto',
    'out', 'outside', 'over', 'past', 'since', 'through', 'throughout',
    'till', 'to', 'toward', 'under', 'underneath', 'until', 'up', 'upon',
    'with', 'within', 'without',
    // Conjunctions (note: 'for' already in prepositions)
    'and', 'but', 'or', 'nor', 'yet', 'so', 'because', 'although',
    'while', 'if', 'when', 'where', 'whether', 'though', 'unless',
    // Other common words
    'as', 'than', 'then', 'just', 'also', 'only', 'even', 'both',
    'each', 'either', 'neither', 'every', 'any', 'all', 'some', 'no',
    'not', 'very', 'too', 'more', 'most', 'less', 'least', 'other',
    'another', 'such', 'same', 'own',
    // UI-specific stop words
    'optional', 'required', 'default', 'value', 'type', 'object',
    'string', 'number', 'boolean', 'array', 'null', 'true', 'false',
  };

  /// Minimum word length to include as keyword.
  static const int minWordLength = 2;

  /// Extracts keywords from a widget/tool name.
  ///
  /// Handles camelCase, snake_case, kebab-case, and PascalCase.
  Set<String> extractFromName(String name) {
    if (name.isEmpty) return {};

    // Split on common separators and case boundaries
    final words = _tokenizeName(name);

    return words
        .map((w) => w.toLowerCase())
        .where((w) => w.length >= minWordLength)
        .where((w) => !stopWords.contains(w))
        .toSet();
  }

  /// Extracts keywords from a description string.
  ///
  /// Filters out stop words and short words.
  Set<String> extractFromDescription(String? description) {
    if (description == null || description.isEmpty) return {};

    // Remove punctuation and split on whitespace
    final words = description
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);

    return words
        .map((w) => w.toLowerCase())
        .where((w) => w.length >= minWordLength)
        .where((w) => !stopWords.contains(w))
        .toSet();
  }

  /// Extracts keywords from a JSON schema.
  ///
  /// Extracts property names, descriptions, and enum values.
  Set<String> extractFromSchema(Map<String, dynamic>? schema) {
    if (schema == null || schema.isEmpty) return {};

    final keywords = <String>{};
    _extractFromSchemaRecursive(schema, keywords);
    return keywords;
  }

  void _extractFromSchemaRecursive(
    Map<String, dynamic> schema,
    Set<String> keywords,
  ) {
    // Extract from description
    if (schema['description'] is String) {
      keywords.addAll(extractFromDescription(schema['description'] as String));
    }

    // Extract from enum values
    if (schema['enum'] is List) {
      for (final value in schema['enum'] as List) {
        if (value is String && value.length >= minWordLength) {
          keywords.add(value.toLowerCase());
        }
      }
    }

    // Extract from properties
    if (schema['properties'] is Map<String, dynamic>) {
      final properties = schema['properties'] as Map<String, dynamic>;
      for (final entry in properties.entries) {
        // Extract from property name
        keywords.addAll(extractFromName(entry.key));

        // Recurse into property schema
        if (entry.value is Map<String, dynamic>) {
          _extractFromSchemaRecursive(
            entry.value as Map<String, dynamic>,
            keywords,
          );
        }
      }
    }

    // Extract from array items
    if (schema['items'] is Map<String, dynamic>) {
      _extractFromSchemaRecursive(
        schema['items'] as Map<String, dynamic>,
        keywords,
      );
    }
  }

  /// Extracts and combines keywords from all sources.
  ///
  /// Returns a sorted list of unique keywords.
  List<String> extractAll({
    required String name,
    String? description,
    Map<String, dynamic>? schema,
  }) {
    final keywords = <String>{};

    keywords.addAll(extractFromName(name));
    keywords.addAll(extractFromDescription(description));
    keywords.addAll(extractFromSchema(schema));

    final sorted = keywords.toList()..sort();
    return sorted;
  }

  /// Tokenizes a name into words.
  List<String> _tokenizeName(String name) {
    // First, replace separators with spaces
    final normalized = name
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    // Handle camelCase and PascalCase by inserting spaces before capitals
    final buffer = StringBuffer();
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      final isUpperCase = char.toUpperCase() == char &&
          char.toLowerCase() != char;

      if (isUpperCase && i > 0) {
        final prevChar = normalized[i - 1];
        final prevIsLower = prevChar.toLowerCase() == prevChar &&
            prevChar.toUpperCase() != prevChar;
        final prevIsSpace = prevChar == ' ';

        // Insert space before uppercase if previous is lowercase
        if (prevIsLower && !prevIsSpace) {
          buffer.write(' ');
        }
        // Handle sequences like 'HTTPClient' -> 'HTTP Client'
        else if (i + 1 < normalized.length) {
          final nextChar = normalized[i + 1];
          final nextIsLower = nextChar.toLowerCase() == nextChar &&
              nextChar.toUpperCase() != nextChar &&
              nextChar != ' ';
          if (nextIsLower && !prevIsSpace) {
            buffer.write(' ');
          }
        }
      }

      buffer.write(char);
    }

    // Split on spaces and filter out numbers-only tokens
    return buffer
        .toString()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) => !RegExp(r'^\d+$').hasMatch(w))
        .toList();
  }
}
