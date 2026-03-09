import 'package:flutter/foundation.dart';
import '../../data/models/event.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/reminder_repository.dart';

class EventProvider with ChangeNotifier {
  final EventRepository _eventRepository = EventRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();

  List<Event> _events = [];
  bool _isLoading = false;

  // Filters
  String _searchQuery = '';
  String _dateFilter = 'All'; // All, Today, This Week, This Month
  int? _selectedCategoryId;
  String? _selectedStatus;
  String _sortOption =
      'Closest Start Time'; // Closest Start Time, Latest Update

  List<Event> get events => _filteredAndSortedEvents();
  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;
  String get dateFilter => _dateFilter;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedStatus => _selectedStatus;
  String get sortOption => _sortOption;

  EventProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await _eventRepository.getAllEvents();
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(String filter) {
    _dateFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSortOption(String option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    await _eventRepository.addEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await _eventRepository.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    await _eventRepository.deleteEvent(id);
    await loadEvents();
  }

  Future<void> updateEventStatus(int id, String newStatus) async {
    final event = _events.firstWhere((e) => e.id == id);
    final updatedEvent = event.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await _eventRepository.updateEvent(updatedEvent);

    // If completed or cancelled, disable reminders
    if (newStatus == 'completed' || newStatus == 'cancelled') {
      final reminders = await _reminderRepository.getRemindersForEvent(id);
      for (var reminder in reminders) {
        if (reminder.isEnabled) {
          final disabledReminder = reminder.copyWith(isEnabled: false);
          await _reminderRepository.updateReminder(disabledReminder);
        }
      }
    }

    await loadEvents();
  }

  List<Event> _filteredAndSortedEvents() {
    List<Event> filtered = _events.where((event) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty &&
          !event.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // 2. Category Filter
      if (_selectedCategoryId != null &&
          event.categoryId != _selectedCategoryId) {
        return false;
      }

      // 3. Status Filter
      if (_selectedStatus != null && event.status != _selectedStatus) {
        return false;
      }

      // 4. Date Filter
      final eventDate = DateTime.parse('${event.eventDate} 00:00:00');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_dateFilter == 'Today') {
        if (eventDate != today) return false;
      } else if (_dateFilter == 'This Week') {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        if (eventDate.isBefore(startOfWeek) || eventDate.isAfter(endOfWeek)) {
          return false;
        }
      } else if (_dateFilter == 'This Month') {
        if (eventDate.year != today.year || eventDate.month != today.month) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortOption == 'Closest Start Time') {
        final aDateTime = DateTime.parse('${a.eventDate} ${a.startTime}:00');
        final bDateTime = DateTime.parse('${b.eventDate} ${b.startTime}:00');
        return aDateTime.compareTo(bDateTime);
      } else {
        // Latest Update
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return filtered;
  }
}
