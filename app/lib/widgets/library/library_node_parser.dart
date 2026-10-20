import 'package:twelve_stars/logic/reader/reader_node_id.dart';

/// Parses a Library bookmark or comment `nodeId` into its constituent
/// `(volumeKey, itemIndex, questionNumber)` components.
(String? volumeKey, int? itemIndex, int? questionNumber) parseLibraryNodeId(
  String nodeId,
) => ReaderNodeId.parseLibrary(nodeId);
