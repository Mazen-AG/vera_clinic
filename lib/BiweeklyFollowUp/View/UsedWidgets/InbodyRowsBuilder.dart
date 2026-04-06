import 'package:flutter/material.dart';
import '../../../Core/Controller/UtilityFunctions.dart';
import '../../../Core/Model/Classes/Client.dart';

import '../../Controller/BiweeklyFollowUpTEC.dart';
import '../../Model/InbodyModels.dart';

List<InbodyAttribute> buildInbodyAttributes(Client client) {
  return [
    InbodyAttribute(
      label: 'الوزن (كجم)',
      previousValueBuilder: (cmfu) {
        final weight = deriveWeightFromBmi(cmfu.mBMI, client.mHeight) ?? 0.0;
        return getDisplayValue(weight);
      },
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mWeightController,
        label: 'الوزن (كجم)',
        hint: 'Weight (kg)',
      ),
    ),
    InbodyAttribute(
      label: 'كتلة العضلات',
      previousValueBuilder: (cmfu) => getDisplayValue(cmfu.mMuscleMass),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mMuscleMassController,
        hint: 'Muscle Mass',
        label: 'كتلة العضلات',
      ),
    ),
    InbodyAttribute(
      label: 'الماء',
      previousValueBuilder: (cmfu) => cmfu.mWater ?? '',
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mWaterController,
        hint: 'Water',
        label: 'الماء',
      ),
    ),
    InbodyAttribute(
      label: 'BMI',
      previousValueBuilder: (cmfu) => getDisplayBMI(client, cmfu.mBMI),
      todayWidget: Align(
        alignment: Alignment.center,
        child: Text(
          computeCurrentBmi(client),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),
    InbodyAttribute(
      label: 'نسبة الدهون',
      previousValueBuilder: (cmfu) => getDisplayValue(cmfu.mPBF, suffix: '%'),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mPBFController,
        label: 'نسبة الدهون',
        hint: 'PBF',
      ),
    ),
    InbodyAttribute(
      label: 'معدل الحرق الأساسي',
      previousValueBuilder: (cmfu) => getDisplayValue(cmfu.mBMR),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mBMRController,
        label: 'معدل الحرق الأساسي',
        hint: 'BMR',
      ),
    ),
    InbodyAttribute(
      label: 'أقصي وزن',
      previousValueBuilder: (cmfu) =>
          getDisplayValue(cmfu.mMaxWeight, suffix: 'كجم'),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mMaxWeightController,
        hint: '',
        label: 'أقصي وزن',
      ),
    ),
    InbodyAttribute(
      label: 'الوزن المثالي',
      previousValueBuilder: (cmfu) =>
          getDisplayValue(cmfu.mOptimalWeight, suffix: 'كجم'),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mOptimalWeightController,
        hint: '',
        label: 'الوزن المثالي',
      ),
    ),
    InbodyAttribute(
      label: 'أقصي سعرات',
      previousValueBuilder: (cmfu) => getDisplayValue(cmfu.mMaxCalories),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mMaxCaloriesController,
        hint: '',
        label: 'أقصي سعرات',
      ),
    ),
    InbodyAttribute(
      label: 'السعرات اليومية',
      previousValueBuilder: (cmfu) => getDisplayValue(cmfu.mDailyCalories),
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mDailyCaloriesController,
        hint: '',
        label: 'السعرات اليومية',
      ),
    ),
    InbodyAttribute(
      label: 'ملاحظات',
      previousValueBuilder: (cmfu) => cmfu.mNotes ?? '',
      todayWidget: _buildTodayInput(
        controller: BiweeklyFollowUpTEC.mNotesController,
        hint: 'أدخل ملاحظات إضافية...',
        label: 'ملاحظات',
        width: 220,
        maxLines: 2,
      ),
    ),
  ];
}

Widget _buildTodayInput({
  required TextEditingController controller,
  required String label,
  required String hint,
  double width = 150,
  int maxLines = 1,
}) {
  return SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, color: Color(0xFF37474F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFFB0BEC5),
          fontWeight: FontWeight.w300,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
        ),
        isDense: true,
      ),
    ),
  );
}

String computeCurrentBmi(Client client) {
  final height = client.mHeight;
  final weightText = BiweeklyFollowUpTEC.mWeightController.text.trim();
  final weight = double.tryParse(weightText);
  if (height == null || height <= 0 || weight == null || weight <= 0) {
    return '';
  }
  final bmi = weight / ((height / 100) * (height / 100));
  return formatOneDecimal(normalizeBmi(bmi));
}
