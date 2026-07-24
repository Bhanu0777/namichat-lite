import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/features/chat/domain/entities/user_search_result.dart';
import 'package:namichat_lite/features/chat/domain/usecases/open_chat_usecase.dart';
import 'package:namichat_lite/features/chat/domain/usecases/search_users_usecase.dart';

/// Represents the current filter applied to the search bar.
enum SearchFilter { all, username, namiId }

class ChatSearchState {
  const ChatSearchState({
    this.query = '',
    this.filter = SearchFilter.all,
    this.isSearching = false,
    this.results = const [],
    this.searchError,
    this.openingChatForUserId,
    this.openChatError,
  });

  final String query;
  final SearchFilter filter;
  final bool isSearching;
  final List<UserSearchResult> results;
  final String? searchError;

  /// User ID currently having a chat opened (drives per-row loading indicator).
  final String? openingChatForUserId;
  final String? openChatError;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results.isNotEmpty;

  ChatSearchState copyWith({
    String? query,
    SearchFilter? filter,
    bool? isSearching,
    List<UserSearchResult>? results,
    String? searchError,
    bool clearSearchError = false,
    String? openingChatForUserId,
    bool clearOpeningChat = false,
    String? openChatError,
    bool clearOpenChatError = false,
  }) {
    return ChatSearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      openingChatForUserId: clearOpeningChat
          ? null
          : (openingChatForUserId ?? this.openingChatForUserId),
      openChatError:
          clearOpenChatError ? null : (openChatError ?? this.openChatError),
    );
  }
}

class ChatSearchNotifier extends StateNotifier<ChatSearchState> {
  ChatSearchNotifier(this._searchUseCase, this._openChatUseCase)
      : super(const ChatSearchState());

  final SearchUsersUseCase _searchUseCase;
  final OpenChatUseCase _openChatUseCase;

  void updateQuery(String query) {
    state = state.copyWith(
      query: query,
      clearSearchError: true,
      clearOpenChatError: true,
    );
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
    }
  }

  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter, clearSearchError: true);
    // Re-run search if there's already a query.
    if (state.hasQuery) {
      search(state.query);
    }
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        results: [],
        isSearching: false,
        clearSearchError: true,
      );
      return;
    }

    state = state.copyWith(isSearching: true, clearSearchError: true);
    final result = await _searchUseCase(trimmed);
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isSearching: false,
        searchError: failure.message,
      ),
      (users) {
        final filtered = _applyFilter(users, state.filter);
        state = state.copyWith(isSearching: false, results: filtered);
      },
    );
  }

  /// Opens or creates a direct chat. Returns the chat ID on success, null on failure.
  Future<String?> openChat(UserSearchResult user) async {
    if (state.openingChatForUserId != null) return null; // debounce

    state = state.copyWith(
      openingChatForUserId: user.id,
      clearOpenChatError: true,
    );

    final result = await _openChatUseCase(
      otherUserId: user.id,
      knownChatId: user.existingChatId,
    );
    if (!mounted) return null;

    return result.fold(
      (failure) {
        state = state.copyWith(
          clearOpeningChat: true,
          openChatError: failure.message,
        );
        return null;
      },
      (chatId) {
        state = state.copyWith(clearOpeningChat: true);
        return chatId;
      },
    );
  }

  void clearError() {
    state = state.copyWith(
      clearSearchError: true,
      clearOpenChatError: true,
    );
  }

  List<UserSearchResult> _applyFilter(
    List<UserSearchResult> users,
    SearchFilter filter,
  ) {
    switch (filter) {
      case SearchFilter.username:
        return users
            .where((u) =>
                u.username.toLowerCase().contains(state.query.toLowerCase()))
            .toList();
      case SearchFilter.namiId:
        return users
            .where((u) =>
                u.namiId
                    ?.toLowerCase()
                    .contains(state.query.toLowerCase()) ??
                false)
            .toList();
      case SearchFilter.all:
        return users;
    }
  }
}

final chatSearchProvider =
    StateNotifierProvider.autoDispose<ChatSearchNotifier, ChatSearchState>(
  (ref) => ChatSearchNotifier(
    ref.watch(searchUsersUseCaseProvider),
    ref.watch(openChatUseCaseProvider),
  ),
);
