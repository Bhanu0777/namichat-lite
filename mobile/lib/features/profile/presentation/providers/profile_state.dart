import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show immutable;
import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';

enum ProfileStatus { initial, loading, loaded, updating, error }

@immutable
class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.errorMessage,
  });

  final ProfileStatus status;
  final ProfileUser? user;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
