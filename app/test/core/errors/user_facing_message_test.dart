import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('userFacingMessage', () {
    test('translates invalid credentials to friendly PT-BR message', () {
      const err = AuthException('Invalid login credentials');
      final msg = userFacingMessage(err);
      expect(msg, contains('E-mail ou senha incorretos'));
      expect(msg.toLowerCase(), isNot(contains('invalid login')));
    });

    test('translates already registered email', () {
      const err = AuthException('User already registered');
      final msg = userFacingMessage(err);
      expect(msg, contains('já está cadastrado'));
    });

    test('translates network/offline errors without technical jargon', () {
      final socketMsg = userFacingMessage(const SocketException('No route'));
      const netFailureMsg = NetworkFailure('SocketException failed host lookup');
      expect(socketMsg, contains('Sem conexão com a internet'));
      expect(userFacingMessage(netFailureMsg), contains('Sem conexão'));
      expect(socketMsg, isNot(contains('SocketException')));
    });

    test('translates timeout errors', () {
      final msg = userFacingMessage(TimeoutException('Timed out after 10s'));
      expect(msg, contains('demorou mais que o esperado'));
    });

    test('translates 5xx / unavailable server errors', () {
      const err = PostgrestException(
        message: '503 Service Unavailable from upstream pg_bouncer',
        code: '503',
      );
      final msg = userFacingMessage(err);
      expect(msg, contains('servidor está temporariamente indisponível'));
      expect(msg, isNot(contains('pg_bouncer')));
    });

    test('preserves ValidationFailure message cleanly', () {
      const failure = ValidationFailure('Informe o peso em kg.');
      expect(userFacingMessage(failure), 'Informe o peso em kg.');
    });

    test('returns generic PT-BR fallback without leaking internal details', () {
      final msg = userFacingMessage(
        Exception('Null check operator used on a null value at foo.dart:99'),
      );
      expect(msg, contains('Algo deu errado'));
      expect(msg, isNot(contains('foo.dart')));
      expect(msg, isNot(contains('Null check')));
    });

    test('invokes appErrorLogger with original error, stackTrace, and context',
        () {
      final prevLogger = appErrorLogger;
      Object? capturedError;
      StackTrace? capturedStack;
      String? capturedContext;
      appErrorLogger = (err, {stackTrace, context}) {
        capturedError = err;
        capturedStack = stackTrace;
        capturedContext = context;
      };
      addTearDown(() => appErrorLogger = prevLogger);

      final trace = StackTrace.fromString('fake stack trace line 1');
      final original = Exception('db failure detail');
      final msg = userFacingMessage(
        original,
        stackTrace: trace,
        context: 'UnitTest.scope',
      );

      expect(msg, contains('Algo deu errado'));
      expect(capturedError, same(original));
      expect(capturedStack, same(trace));
      expect(capturedContext, 'UnitTest.scope');
    });

    test('returns local-storage message and hides offline safety note on CacheFailure',
        () {
      const cacheErr = CacheFailure('Corrupted SharedPreferences JSON');
      final msg = userFacingMessage(cacheErr);
      expect(msg, contains('dados locais neste aparelho'));
      expect(msg, isNot(contains('SharedPreferences')));
      expect(offlineSafetyNoteFor(cacheErr), isNull);
      expect(
        offlineSafetyNoteFor(const NetworkFailure('No route')),
        kOfflineDataSafetyNote,
      );
    });

    test('translates expired or already-used recovery links to friendly PT-BR copy',
        () {
      const expired = AuthException(
        'Email link is invalid or has expired',
        statusCode: '403',
        code: 'otp_expired',
      );
      const invalidGrant = AuthException(
        'invalid_grant: token has already been used',
      );
      expect(isExpiredOrUsedAuthLinkError(expired), isTrue);
      expect(isExpiredOrUsedAuthLinkError(invalidGrant), isTrue);
      expect(
        userFacingMessage(expired),
        'Este link de redefinição expirou ou já foi utilizado. Solicite um novo link para continuar.',
      );
    });
  });
}
