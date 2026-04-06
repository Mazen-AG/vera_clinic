import 'package:flutter_test/flutter_test.dart';
import 'package:vera_clinic/Core/Model/Classes/Visit.dart';
import 'package:vera_clinic/Core/Model/Classes/ClientMonthlyFollowUp.dart';
import 'package:vera_clinic/Core/Model/Classes/Client.dart';
import 'package:vera_clinic/Core/Controller/UtilityFunctions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('BMI and Data Integrity Tests', () {
    test('Visit.fromFirestore handles int values for weight and bmi', () {
      final Map<String, dynamic> data = {
        'visitId': 'v1',
        'clientId': 'c1',
        'date': Timestamp.fromDate(DateTime.now()),
        'diet': 'Diet A',
        'weight': 80, // int in Firestore
        'bmi': 25, // int in Firestore
        'visitNotes': 'Notes',
      };

      final visit = Visit.fromFirestore(data);
      expect(visit.mWeight, 80.0);
      expect(visit.mBMI, 25.0);
    });

    test(
        'ClientMonthlyFollowUp.fromFirestore handles int values for all double fields',
        () {
      final Map<String, dynamic> data = {
        'clientMonthlyFollowUpId': 'cmfu1',
        'clientId': 'c1',
        'BMI': 22,
        'PBF': 15,
        'water': '2L',
        'maxWeight': 75,
        'optimalWeight': 70,
        'BMR': 1800,
        'maxCalories': 2200,
        'dailyCalories': 2000,
        'muscleMass': 35,
        'date': Timestamp.fromDate(DateTime.now()),
        'notes': 'Some notes',
      };

      final cmfu = ClientMonthlyFollowUp.fromFirestore(data);
      expect(cmfu.mBMI, 22.0);
      expect(cmfu.mMuscleMass, 35.0);
      expect(cmfu.mBMR, 1800.0);
    });

    test('getDisplayBMI calculates fallback only if bmi is 0', () {
      final client = Client(
        clientId: 'c1',
        name: 'Test',
        clientPhoneNum: '123',
        gender: Gender.male,
        lastVisitId: '',
        birthdate: null,
        clientConstantInfoId: '',
        diseaseId: '',
        diet: '',
        plat: [],
        clientLastMonthlyFollowUpId: '',
        preferredFoodsId: '',
        weightAreasId: '',
        notes: '',
        height: 170.0,
        weight: 70.0, // Calculated BMI should be ~24.2
        subscriptionType: SubscriptionType.none,
      );

      // Case 1: Custom BMI provided
      expect(getDisplayBMI(client, 28.5), '28.5');

      // Case 2: BMI is 0, should calculate fallback
      // 70 / (1.7 * 1.7) = 24.22...
      expect(getDisplayBMI(client, 0.0), '24.2');

      // Case 3: BMI is null, should calculate fallback
      expect(getDisplayBMI(client, null), '24.2');
    });

    test('getDisplayValue handles 0 and null correctly', () {
      expect(getDisplayValue(25.0), '25.0');
      expect(getDisplayValue(0.0), 'غير متوفر');
      expect(getDisplayValue(null), 'غير متوفر');
      expect(getDisplayValue(25.0, suffix: 'kg'), '25.0 kg');
    });
  });
}
