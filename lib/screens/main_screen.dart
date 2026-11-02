import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'add_session_screen.dart';
import '../models/study_session.dart';
import '../utils/database_helper.dart';
import '../utils/dummy_data.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _titleTapCount = 0;

  final DatabaseHelper _database = DatabaseHelper.instance;
  final List<StudySession> _sessions = [];

  // Pagination
  static const int _pageSize = 10;
  int _currentPage = 1;
  int _totalCount = 0;
  int _nonFavoriteCount = 0;
  int _totalMinutes = 0;
  bool _isLoading = true;

  int get _pageCount => (_totalCount + _pageSize - 1) ~/ _pageSize;

  void _handleTitleTap() {
    if (_titleTapCount >= 7) return;
    setState(() => _titleTapCount++);
  }

  @override
  void initState() {
    super.initState();
    _refreshPage(goToFirstPage: true);
  }

  Future<void> _refreshPage({bool goToFirstPage = false}) async {
    if (!mounted) return;
    final refreshStartedAt = DateTime.now();
    setState(() => _isLoading = true);

    try {
      final count = await _database.getSessionsCount();
      final nonFavoriteCount = await _database.getNonFavoriteSessionsCount();
      final totalMinutes = await _database.getTotalDuration();
      final lastPage = count == 0 ? 1 : (count + _pageSize - 1) ~/ _pageSize;
      if (goToFirstPage) {
        _currentPage = 1;
      } else if (_currentPage > lastPage) {
        _currentPage = lastPage;
      }
      final sessions = await _database.getPaginatedSessions(
        page: _currentPage,
        limit: _pageSize,
      );

      final remainingLoadingTime = const Duration(milliseconds: 1500) -
          DateTime.now().difference(refreshStartedAt);
      if (remainingLoadingTime > Duration.zero) {
        await Future<void>.delayed(remainingLoadingTime);
      }

      if (!mounted) return;
      setState(() {
        _totalCount = count;
        _nonFavoriteCount = nonFavoriteCount;
        _totalMinutes = totalMinutes;
        _sessions
          ..clear()
          ..addAll(sessions);
        _isLoading = false;
      });
    } catch (error) {
      final remainingLoadingTime = const Duration(milliseconds: 1500) -
          DateTime.now().difference(refreshStartedAt);
      if (remainingLoadingTime > Duration.zero) {
        await Future<void>.delayed(remainingLoadingTime);
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load study sessions: $error')),
      );
    }
  }

  Future<void> _changePage(int page) async {
    if (page < 1 || page > _pageCount || page == _currentPage) return;
    setState(() => _currentPage = page);
    await _refreshPage();
  }

  Future<void> _toggleFavorite(int index) async {
    final session = _sessions[index];
    final updatedSession = session.copyWith(isFavorite: !session.isFavorite);
    await _database.updateSession(updatedSession);
    await _refreshPage();
  }

  Future<void> _addSession() async {
    final session = await Navigator.of(context).push<StudySession>(
      MaterialPageRoute(builder: (_) => const AddSessionScreen()),
    );
    if (session == null || !mounted) return;
    try {
      await _database.insertSession(session);
      if (!mounted) return;
      await _refreshPage(goToFirstPage: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study session saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save study session: $error')),
      );
    }
  }

  Future<void> _editSession(int index) async {
    final existingSession = _sessions[index];
    final updatedSession = await Navigator.of(context).push<StudySession>(
      MaterialPageRoute(
        builder: (_) => AddSessionScreen(sessionToEdit: existingSession),
      ),
    );

    if (updatedSession == null || !mounted) return;
    try {
      await _database.updateSession(updatedSession);
      if (!mounted) return;
      await _refreshPage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study session updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update study session: $error')),
      );
    }
  }

  Future<bool> _confirmDelete(int index) async {
    final session = _sessions[index];
    if (session.isFavorite || session.id == null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Session?'),
        content: Text('Are you sure you want to delete "${session.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _database.deleteSession(session.id!);
      await _refreshPage();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${session.title}"')),
      );
      return true;
    }
    return false;
  }

  void _showSessionDetails(int index) {
    final session = _sessions[index];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(session.subject)),
                  _durationChip(context, session.duration),
                ],
              ),
              const SizedBox(height: 20),
              Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(session.notes ?? 'No notes added for this session.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop();
              _editSession(index);
            },
          ),
        ],
      ),
    );
  }

  void _showSessionActions(int index) {
    final session = _sessions[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _durationChip(context, session.duration),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session.subject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: session.isFavorite ? Colors.black38 : Colors.redAccent,
                        side: BorderSide(color: session.isFavorite ? Colors.black26 : Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                      onPressed: session.isFavorite ? null : () {
                        Navigator.pop(context);
                        _confirmDelete(index);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(context);
                        _editSession(index);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _seedDummyData() {
    _seedDummyRecords();
  }

  Future<void> _seedDummyRecords() async {
    final dummyItems = generateDummySessions(50);
    for (final session in dummyItems) {
      await _database.insertSession(session);
    }
    if (!mounted) return;
    await _refreshPage(goToFirstPage: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added 50 dummy study sessions!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _clearAllData() async {
    final count = await _database.getNonFavoriteSessionsCount();
    if (count == 0 || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Study Sessions?'),
        content: Text('This will permanently delete $count non-favorited study ${count == 1 ? 'session' : 'sessions'}. Favorited records will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _database.deleteNonFavoriteSessions();
      await _refreshPage(goToFirstPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: const Text('Study Tracker'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh study sessions',
            onPressed: () => _refreshPage(),
          ),
          if (_titleTapCount >= 7)
            IconButton(
              icon: const Icon(Icons.bug_report_rounded),
              tooltip: 'Add 50 Dummy Records',
              onPressed: _seedDummyData,
            ),
          if (kDebugMode) ...[
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: 'Delete All Study Sessions',
              onPressed: _nonFavoriteCount == 0 ? null : _clearAllData,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty ? _emptyState(context) : Column(
          children: [
            _summaryHeader(context),
            Expanded(child: _sessionList(context)),
            _paginationControls(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSession,
        tooltip: 'Add study session',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryHeader(BuildContext context) {
    final hours = _totalMinutes ~/ 60;
    final minutes = _totalMinutes % 60;
    final timeString = hours > 0 ? '${hours}h ${minutes}m' : '$minutes mins';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Time Studied',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Text(
            timeString,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 100),
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your study log starts here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep track of what you learn, one session at a time. Tap + to add your first entry.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.black54, height: 1.5),
          ),
        ],
      );

  Widget _paginationControls(BuildContext context) {
    final pageCount = _pageCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            'Page $_currentPage of $pageCount',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: _currentPage < pageCount
                ? () => _changePage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _sessionList(BuildContext context) {
    final displayedSessions = List<StudySession>.of(_sessions);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: displayedSessions.length,
      itemBuilder: (context, index) {
        final sessionIndex = index;
        final session = displayedSessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: ValueKey(session.id),
            direction: session.isFavorite ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
            ),
            confirmDismiss: (direction) async {
              return await _confirmDelete(sessionIndex);
            },
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE9EAF1)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showSessionDetails(sessionIndex),
                onLongPress: () => _showSessionActions(sessionIndex),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              session.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: session.isFavorite ? Colors.orange : Colors.black26,
                              size: 26,
                            ),
                            onPressed: () => _toggleFavorite(sessionIndex),
                          ),
                          const SizedBox(width: 12),
                          _durationChip(context, session.duration),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            session.subject,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      if (session.notes != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          session.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _durationChip(BuildContext context, int duration) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$duration min',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
}
