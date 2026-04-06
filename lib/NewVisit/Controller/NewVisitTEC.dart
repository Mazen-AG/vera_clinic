import 'package:flutter/cupertino.dart';

import '../../Core/Model/Classes/Visit.dart';

class NewVisitTEC{
  // Visit
  static late TextEditingController visitDateController;
  static late TextEditingController visitDietController;
  static late TextEditingController visitWeightController;
  static late TextEditingController visitNotesController;
  static List<Visit> clientVisits = [];

  static double? _clientHeight;
  static double? get clientHeight => _clientHeight;

  static void init({double? clientHeight}) {
    _clientHeight = clientHeight;
    visitDateController = TextEditingController();
    visitDietController = TextEditingController();
    visitWeightController = TextEditingController();
    visitNotesController = TextEditingController();
  }

  static void clear() {
    visitDateController.clear();
    visitDietController.clear();
    visitWeightController.clear();
    visitNotesController.clear();
  }

  static void dispose() {
    visitDateController.dispose();
    visitDietController.dispose();
    visitWeightController.dispose();
    visitNotesController.dispose();
  }
}