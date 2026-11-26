import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AppErrorLogger = void Function(
  Object error, {
  StackTrace? stackTrace,
  String? context,
});

AppErrorLogger appErrorLogger = _defaultAppErrorLogger;

void _defaultAppErrorLogger(
  Object error, {
  StackTrace? stackTrace,
  String? context,
}) {
  developer.log(
    context != null ? '[$context] $error' : '$error',
    name: 'LIFTR.Error',
    level: 1000,
    error: error,
    stackTrace: stackTrace ?? (error is Failure ? error.stackTrace : null),
  );
}

const String kOfflineDataSafetyNote =
    'Seus treinos continuam salvos neste aparelho.';

/// Returns `true` when [error] originates from local device cache/storage
/// rather than a remote API or network layer.
bool isLocalStorageError(Object error) {
  if (error is CacheFailure) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('cachefailure') ||
      msg.contains('localdatasource') ||
      msg.contains('sharedpreferences') ||
      msg.contains('sqlite') ||
      msg.contains('drift');
}

/// Returns [kOfflineDataSafetyNote] only when [error] does NOT stem from a
/// local cache/storage read/write failure.
String? offlineSafetyNoteFor(Object error) =>
    isLocalStorageError(error) ? null : kOfflineDataSafetyNote;

/// Translates technical exceptions and [Failure] objects into clear,
/// non-technical PT-BR messages with cause and next step while logging the
/// original error and stack trace.
String userFacingMessage(
  Object error, {
  StackTrace? stackTrace,
  String? context,
  bool logError = true,
}) {
  if (logError) {
    appErrorLogger(
      error,
      stackTrace: stackTrace ?? (error is Failure ? error.stackTrace : null),
      context: context,
    );
  }
  if (error is CacheFailure) {
    return 'Não foi possível ler ou salvar os dados locais neste aparelho. Tente novamente.';
  }
  if (error is ValidationFailure && error.message.trim().isNotEmpty) {
    return error.message.trim();
  }
  if (error is NetworkFailure ||
      error is SocketException ||
      isNetworkError(error)) {
    if (error is TimeoutException ||
        error.toString().toLowerCase().contains('timed out')) {
      return 'A operação demorou mais que o esperado. Verifique sua conexão e tente novamente.';
    }
    return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
  }
  if (error is TimeoutException) {
    return 'A operação demorou mais que o esperado. Verifique sua conexão e tente novamente.';
  }

  final rawMessage = switch (error) {
    final AuthException e => e.message,
    final PostgrestException e => e.message,
    final Failure f => f.message,
    _ => error.toString(),
  };
  final lower = rawMessage.toLowerCase();
  final statusCode = switch (error) {
    final AuthException e => e.statusCode ?? '',
    final PostgrestException e => e.code ?? '',
    _ => '',
  }.toLowerCase();

  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid_credentials') ||
      lower.contains('invalid email or password')) {
    return 'E-mail ou senha incorretos. Confira seus dados e tente novamente.';
  }

  if (lower.contains('email not confirmed')) {
    return 'Confirme seu e-mail pelo link enviado antes de entrar.';
  }

  if (lower.contains('user already registered') ||
      lower.contains('already been registered') ||
      lower.contains('already registered') ||
      lower.contains('email already exists')) {
    return 'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.';
  }

  if (lower.contains('password should be') || lower.contains('weak password')) {
    return 'A senha precisa ter pelo menos 6 caracteres. Escolha outra senha e tente novamente.';
  }

  if (lower.contains('too many requests') ||
      lower.contains('rate limit') ||
      statusCode == '429') {
    return 'Muitas tentativas em sequência. Aguarde alguns instantes e tente novamente.';
  }

  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'A operação demorou mais que o esperado. Verifique sua conexão e tente novamente.';
  }

  if (lower.contains('service unavailable') ||
      lower.contains('bad gateway') ||
      lower.contains('internal server error') ||
      lower.contains('servidor indispon') ||
      lower.contains('500') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('504') ||
      statusCode.startsWith('5')) {
    return 'O servidor está temporariamente indisponível. Tente novamente em instantes.';
  }

  if (error is ServerFailure || error is PostgrestException) {
    return 'Não foi possível concluir a solicitação agora. Tente novamente em instantes.';
  }

  return 'Algo deu errado ao concluir a operação. Tente novamente em instantes.';
}
