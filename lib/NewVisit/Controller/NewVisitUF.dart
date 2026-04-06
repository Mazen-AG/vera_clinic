import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vera_clinic/Core/Controller/Providers/VisitProvider.dart';
import 'package:vera_clinic/Core/Controller/UtilityFunctions.dart';
import 'package:vera_clinic/Core/Model/Classes/Visit.dart';
import 'package:vera_clinic/Core/View/PopUps/InvalidDataTypeSnackBar.dart';
import 'package:vera_clinic/NewVisit/Controller/NewVisitTEC.dart';

import '../../Core/View/PopUps/RequiredFieldSnackBar.dart';

import '../../Core/Services/DebugLoggerService.dart';
Future<bool> createVisit(BuildContext context) async {
  try {
    double weight = double.tryParse(NewVisitTEC.visitWeightController.text) ?? 0.0;
    double bmi = 0.0;
    if (weight > 0 && NewVisitTEC.clientHeight != null && NewVisitTEC.clientHeight! > 0) {
      bmi = normalizeBmi(weight / ((NewVisitTEC.clientHeight! / 100) * (NewVisitTEC.clientHeight! / 100)));
    }

    Visit v = Visit(
      visitId: '',
      clientId: '',
      date: DateTime.tryParse(NewVisitTEC.visitDateController.text) ??
          DateTime.now(),
      diet: NewVisitTEC.visitDietController.text,
      weight: weight,
      bmi: bmi,
      visitNotes: NewVisitTEC.visitNotesController.text,
    );

    await context.read<VisitProvider>().createVisit(v);

    NewVisitTEC.clientVisits.add(v);
    return true;
  } on Exception catch (e) {
    mDebug("Error creating visit: $e");
    return false;
  }
}

bool verifyVisitInput(
    BuildContext context,
    TextEditingController weightController,
    TextEditingController dateController) {
  bool isValid = true;
  if (!isNumOnly(weightController.text)) {
    showInvalidDataTypeSnackBar(context, 'الوزن');
    isValid = false;
  }

  if (weightController.text.isEmpty) {
    showRequiredFieldSnackBar(context, 'الوزن');
    isValid = false;
  }
  if (dateController.text.isEmpty) {
    showRequiredFieldSnackBar(context, 'تاريخ الزيارة');
    isValid = false;
  }
  return isValid;
}

String? getLatestVisitId() {
  //todo: optimize?
  Visit latestVisit = NewVisitTEC.clientVisits.last;
  if (NewVisitTEC.clientVisits.isNotEmpty) {
    for (Visit v in NewVisitTEC.clientVisits) {
      if (v.mDate.isAfter(latestVisit.mDate)) {
        latestVisit = v;
      }
    }
  }
  return latestVisit.mVisitId;
}
