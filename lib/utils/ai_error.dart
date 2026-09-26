import 'dart:async';

/// Whether an AI error is a temporary overload or rate limit that is worth
/// retrying automatically, based on the lower-cased error text.
bool isTransientAiError(String lowerCaseMessage) {
  const signals = [
    '429',
    'rate limit',
    'resource_exhausted',
    'quota',
    '503',
    'unavailable',
    'high demand',
    'overloaded',
  ];
  return signals.any(lowerCaseMessage.contains);
}

/// A short, friendly explanation of why an AI request failed.
String aiErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'The AI took too long to respond. Please try again.';
  }
  if (error is FormatException) {
    return 'The AI gave an unexpected answer. Please try again.';
  }
  final message = error.toString().toLowerCase();
  if (message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network') ||
      message.contains('connection')) {
    return 'No internet connection. Connect and try again.';
  }
  if (isTransientAiError(message)) {
    return 'The AI is busy right now. Please try again in a moment.';
  }
  return 'Something went wrong with the AI. Please try again.';
}
