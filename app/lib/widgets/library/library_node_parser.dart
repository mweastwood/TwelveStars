/// Parses a library nodeId into its constituent components:
/// volumeKey (if prefixed), itemIndex, and questionNumber.
(String? volKey, int? itemIdx, int? qNum) parseLibraryNodeId(String nodeId) {
  String? volumeKey;
  int? itemIndex;
  int? questionNumber;

  String cleanNodeId = nodeId;
  if (nodeId.contains(':')) {
    final parts = nodeId.split(':');
    volumeKey = parts.first;
    cleanNodeId = parts.sublist(1).join(':');
  }

  if (cleanNodeId.contains('_')) {
    final lastPart = cleanNodeId.split('_').last;
    if (lastPart.startsWith('q')) {
      questionNumber = int.tryParse(lastPart.substring(1));
    } else {
      itemIndex = int.tryParse(lastPart);
    }
  } else if (cleanNodeId.contains('-')) {
    final lastPart = cleanNodeId.split('-').last;
    itemIndex = int.tryParse(lastPart);
  }

  return (volumeKey, itemIndex, questionNumber);
}
