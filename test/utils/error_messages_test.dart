import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder_ai/utils/ai_error.dart';
import 'package:resume_builder_ai/utils/auth_error.dart';

void main() {
  group('isTransientAiError', () {
    test('retries rate limits and overloads', () {
      expect(isTransientAiError('server error [429]: rate limit'), isTrue);
      expect(isTransientAiError('status: resource_exhausted'), isTrue);
      expect(isTransientAiError('[503] model is overloaded'), isTrue);
      expect(isTransientAiError('high demand, try later'), isTrue);
    });

    test('does not retry errors that merely mention generateContent', () {
      expect(
        isTransientAiError('models/x is not supported for generatecontent'),
        isFalse,
      );
    });
  });

  group('aiErrorMessage', () {
    test('explains timeouts, bad responses, offline and overload', () {
      expect(aiErrorMessage(TimeoutException('')), contains('too long'));
      expect(aiErrorMessage(const FormatException()), contains('unexpected'));
      expect(
        aiErrorMessage(const SocketException('Failed host lookup')),
        contains('No internet'),
      );
      expect(aiErrorMessage(Exception('[503] high demand')), contains('busy'));
      expect(aiErrorMessage(Exception('boom')), contains('try again'));
    });
  });

  group('authErrorMessage', () {
    test('maps common Firebase Auth errors', () {
      expect(
        authErrorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'Incorrect email or password.',
      );
      expect(
        authErrorMessage(FirebaseAuthException(code: 'network-request-failed')),
        contains('No internet'),
      );
    });

    test('maps Google sign-in platform errors', () {
      expect(
        authErrorMessage(PlatformException(code: 'network_error')),
        contains('No internet'),
      );
      expect(
        authErrorMessage(PlatformException(code: 'sign_in_failed')),
        contains('Google sign-in failed'),
      );
    });
  });
}
