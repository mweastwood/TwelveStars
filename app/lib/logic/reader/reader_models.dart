enum ReaderNodeType { verse, heading, paragraph, qa }

class ReaderContentNode {
  final String id;
  final ReaderNodeType nodeType;
  final String? primaryText;
  final String? secondaryText;
  final String? questionNumber;
  final String? question;
  final String? answer;
  final String? explanation;
  final List<String>? citations;
  final String? crossRefId;

  const ReaderContentNode({
    required this.id,
    required this.nodeType,
    this.primaryText,
    this.secondaryText,
    this.questionNumber,
    this.question,
    this.answer,
    this.explanation,
    this.citations,
    this.crossRefId,
  });
}

class ReaderTocEntry {
  final int index;
  final String title;
  final String? subtitle;
  final List<ReaderTocEntry>? children;

  const ReaderTocEntry({
    required this.index,
    required this.title,
    this.subtitle,
    this.children,
  });
}

class ReaderSection {
  final int sectionIndex;
  final String title;
  final String? subtitle;
  final List<ReaderContentNode> nodes;

  const ReaderSection({
    required this.sectionIndex,
    required this.title,
    this.subtitle,
    required this.nodes,
  });
}

class ReaderDocument {
  final String documentId;
  final String title;
  final String? subtitle;
  final String? author;
  final int sectionsCount;
  final List<ReaderTocEntry> tocEntries;

  const ReaderDocument({
    required this.documentId,
    required this.title,
    this.subtitle,
    this.author,
    required this.sectionsCount,
    required this.tocEntries,
  });
}

class ReaderBookmark {
  final String id;
  final String documentId;
  final int sectionIndex;
  final String nodeId;
  final String textPreview;
  final DateTime timestamp;

  const ReaderBookmark({
    required this.id,
    required this.documentId,
    required this.sectionIndex,
    required this.nodeId,
    required this.textPreview,
    required this.timestamp,
  });
}
