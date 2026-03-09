import '../models/reminder.dart';
import '../db/app_database.dart';

class ReminderRepository {
  final _dbInstance = AppDatabase.instance;

  Future<List<Reminder>> getRemindersForEvent(int eventId) async {
    final db = await _dbInstance.database;
    final result = await db.query(
      'reminders',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'minutes_before ASC',
    );
    return result.map((e) => Reminder.fromMap(e)).toList();
  }

  Future<int> addReminder(Reminder reminder) async {
    final db = await _dbInstance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await _dbInstance.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _dbInstance.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
