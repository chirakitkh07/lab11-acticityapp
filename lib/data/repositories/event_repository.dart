import '../models/event.dart';
import '../db/app_database.dart';

class EventRepository {
  final _dbInstance = AppDatabase.instance;

  Future<List<Event>> getAllEvents() async {
    final db = await _dbInstance.database;
    final result = await db.query(
      'events',
      orderBy: 'event_date DESC, start_time DESC',
    );
    return result.map((e) => Event.fromMap(e)).toList();
  }

  Future<Event> getEventById(int id) async {
    final db = await _dbInstance.database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Event.fromMap(result.first);
    }
    throw Exception('Event $id not found');
  }

  Future<int> addEvent(Event event) async {
    final db = await _dbInstance.database;
    return await db.insert('events', event.toMap());
  }

  Future<int> updateEvent(Event event) async {
    final db = await _dbInstance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _dbInstance.database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
