import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fooddelivery/food_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FoodApp());
}
