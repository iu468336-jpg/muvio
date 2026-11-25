import 'package:flutter/foundation.dart';

/// Typed failure hierarchy for clean error handling without uncaught exceptions.
sealed class AppFailure {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  String get kindLabel;

  @override
  String toString() => '$kindLabel: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause, this.statusCode});

  final int? statusCode;

  @override
  String get kindLabel => 'NetworkFailure';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});

  @override
  String get kindLabel => 'ValidationFailure';
}

final class ParseFailure extends AppFailure {
  const ParseFailure(super.message, {super.cause});

  @override
  String get kindLabel => 'ParseFailure';
}

final class AddonOfflineFailure extends AppFailure {
  const AddonOfflineFailure(super.message, {super.cause});

  @override
  String get kindLabel => 'AddonOfflineFailure';
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});

  @override
  String get kindLabel => 'StorageFailure';
}

/// Functional result monad avoiding exceptions across data and domain layers.
@immutable
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final failure) => failure,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final failure) => onFailure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}
