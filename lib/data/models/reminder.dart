class Reminder {
  final int? id;
  final int eventId;
  final int minutesBefore;
  final DateTime remindAt;
  final bool isEnabled; // 0/1 in db

  Reminder({
    this.id,
    required this.eventId,
    required this.minutesBefore,
    required this.remindAt,
    required this.isEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'minutes_before': minutesBefore,
      'remind_at': remindAt.toIso8601String(),
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      eventId: map['event_id'],
      minutesBefore: map['minutes_before'],
      remindAt: DateTime.parse(map['remind_at']),
      isEnabled: map['is_enabled'] == 1,
    );
  }

  Reminder copyWith({
    int? id,
    int? eventId,
    int? minutesBefore,
    DateTime? remindAt,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      remindAt: remindAt ?? this.remindAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
