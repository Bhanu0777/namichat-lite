import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:namichat_lite/core/constants/app_constants.dart';
import 'package:namichat_lite/core/network/dio_client.dart';
import 'package:namichat_lite/core/network/socket_service.dart';
import 'package:namichat_lite/core/network/websocket_client.dart';
import 'package:namichat_lite/core/storage/local_storage.dart';
import 'package:namichat_lite/core/storage/secure_storage.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';

import 'package:namichat_lite/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:namichat_lite/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:namichat_lite/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';
import 'package:namichat_lite/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';
import 'package:namichat_lite/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:namichat_lite/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:namichat_lite/features/chat/domain/repositories/chat_repository.dart';
import 'package:namichat_lite/features/chat/domain/usecases/fetch_messages_usecase.dart';
import 'package:namichat_lite/features/chat/domain/usecases/open_chat_usecase.dart';
import 'package:namichat_lite/features/chat/domain/usecases/search_users_usecase.dart';
import 'package:namichat_lite/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:namichat_lite/features/groups/data/repositories/group_repository_impl.dart';
import 'package:namichat_lite/features/groups/domain/repositories/group_repository.dart';
import 'package:namichat_lite/features/groups/domain/usecases/group_usecases.dart';
import 'package:namichat_lite/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:namichat_lite/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:namichat_lite/features/profile/domain/repositories/profile_repository.dart';
import 'package:namichat_lite/features/profile/domain/usecases/profile_usecases.dart';

// ---------------------------------------------------------------------------
// Core dependency graph (infrastructure, framework-agnostic).
// Feature modules register their providers in this file as they are added.
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(const FlutterSecureStorage()),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(Hive.box(AppHiveBox.name)),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(ref.watch(secureStorageProvider)),
);

final webSocketClientProvider = Provider<WebSocketClient>(
  (ref) => WebSocketClient(baseWsUrl: AppConstants.wsBaseUrl),
);

/// Creates and manages a [SocketService] per chat room.
/// Auto-disposes when the chat page leaves the widget tree.
final socketServiceProvider =
    Provider.autoDispose.family<SocketService, String>((ref, chatId) {
  final secure = ref.watch(secureStorageProvider);
  final service = SocketService(
    transport: WebSocketClient(baseWsUrl: AppConstants.wsBaseUrl),
    chatId: chatId,
    getToken: () => secure.read(StorageKeys.accessToken),
  );
  ref.onDispose(service.dispose);
  return service;
});

// ---------------------------------------------------------------------------
// Feature: Authentication
// ---------------------------------------------------------------------------

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioClientProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(
    ref.watch(secureStorageProvider),
    ref.watch(localStorageProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);
final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(loginUseCaseProvider),
    ref.watch(registerUseCaseProvider),
    ref.watch(getCurrentUserUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
  );
});

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>(
  (ref) => ChatRemoteDataSource(ref.watch(dioClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider)),
);

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>(
  (ref) => SearchUsersUseCase(ref.watch(chatRepositoryProvider)),
);

final openChatUseCaseProvider = Provider<OpenChatUseCase>(
  (ref) => OpenChatUseCase(ref.watch(chatRepositoryProvider)),
);

final fetchMessagesUseCaseProvider = Provider<FetchMessagesUseCase>(
  (ref) => FetchMessagesUseCase(ref.watch(chatRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Feature: Groups
// ---------------------------------------------------------------------------

final groupRemoteDataSourceProvider = Provider<GroupRemoteDataSource>(
  (ref) => GroupRemoteDataSource(ref.watch(dioClientProvider)),
);

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepositoryImpl(ref.watch(groupRemoteDataSourceProvider)),
);

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>(
  (ref) => CreateGroupUseCase(ref.watch(groupRepositoryProvider)),
);
final listMyGroupsUseCaseProvider = Provider<ListMyGroupsUseCase>(
  (ref) => ListMyGroupsUseCase(ref.watch(groupRepositoryProvider)),
);
final getGroupUseCaseProvider = Provider<GetGroupUseCase>(
  (ref) => GetGroupUseCase(ref.watch(groupRepositoryProvider)),
);
final updateGroupUseCaseProvider = Provider<UpdateGroupUseCase>(
  (ref) => UpdateGroupUseCase(ref.watch(groupRepositoryProvider)),
);
final deleteGroupUseCaseProvider = Provider<DeleteGroupUseCase>(
  (ref) => DeleteGroupUseCase(ref.watch(groupRepositoryProvider)),
);
final joinGroupByCodeUseCaseProvider = Provider<JoinGroupByCodeUseCase>(
  (ref) => JoinGroupByCodeUseCase(ref.watch(groupRepositoryProvider)),
);
final regenerateInviteCodeUseCaseProvider =
    Provider<RegenerateInviteCodeUseCase>(
  (ref) => RegenerateInviteCodeUseCase(ref.watch(groupRepositoryProvider)),
);
final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>(
  (ref) => RemoveMemberUseCase(ref.watch(groupRepositoryProvider)),
);
final promoteMemberUseCaseProvider = Provider<PromoteMemberUseCase>(
  (ref) => PromoteMemberUseCase(ref.watch(groupRepositoryProvider)),
);

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(ref.watch(dioClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)),
);
