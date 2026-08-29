import 'package:hive_flutter/hive_flutter.dart';

class HiveSetup {
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // TODO: Register adapters here
    // Hive.registerAdapter(HabitAdapter());
    // Hive.registerAdapter(UserProgressAdapter());
    
    // TODO: Open boxes here
    // await Hive.openBox<Habit>('habits');
    // await Hive.openBox<UserProgress>('progress');
  }
}
