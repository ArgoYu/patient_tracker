enum ConversationType {
  coach,
  physician,
  nurse,
  peer,
  group,
}

ConversationType? conversationTypeFromString(String? value) {
  if (value == null) return null;
  for (final type in ConversationType.values) {
    if (type.name == value) return type;
  }
  return null;
}
