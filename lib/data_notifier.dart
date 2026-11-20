import 'package:flutter/foundation.dart';

class DataNotifier extends ChangeNotifier {
  static final DataNotifier instance = DataNotifier._();
  DataNotifier._();
  void notify() => notifyListeners();
}