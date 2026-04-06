import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vera_clinic/Core/Controller/Providers/ClinicProvider.dart';
import 'package:vera_clinic/Core/View/PopUps/MySnackBar.dart';

import '../../Core/Controller/Providers/ClientConstantInfoProvider.dart';
import '../../Core/Controller/Providers/ClientMonthlyFollowUpProvider.dart';
import '../../Core/Controller/Providers/ClientProvider.dart';
import '../../Core/Controller/Providers/DiseaseProvider.dart';
import '../../Core/Controller/Providers/PreferredFoodsProvider.dart';
import '../../Core/Controller/Providers/VisitProvider.dart';
import '../../Core/Controller/Providers/WeightAreasProvider.dart';
import '../../Core/Controller/UtilityFunctions.dart';
import '../../Core/Model/Classes/Client.dart';
import '../../Core/Model/Classes/ClientConstantInfo.dart';
import '../../Core/Model/Classes/ClientMonthlyFollowUp.dart';
import '../../Core/Model/Classes/Disease.dart';
import '../../Core/Model/Classes/PreferredFoods.dart';
import '../../Core/Model/Classes/Visit.dart';
import '../../Core/Model/Classes/WeightAreas.dart';
import '../../NewVisit/Controller/NewVisitTEC.dart';
import '../../NewVisit/Controller/NewVisitUF.dart';
import 'ClientRegistrationTEC.dart';

import '../../Core/Services/DebugLoggerService.dart';
Future<bool> checkInNewClient(BuildContext context, Client c) async {
  try {
    final clinicProvider = context.read<ClinicProvider>();
    // Check if the client is already checked in
    if (clinicProvider.checkedInClients
        .any((client) => client.mClientId == c.mClientId)) {
      showMySnackBar(context, 'هذا العميل مسجل مسبقًا', Colors.red);
      return false;
    }
    await clinicProvider.checkInClient(c, DateTime.now().toIso8601String());
    return true;
  } on Exception catch (e) {
    mDebug('Error checking in new client: $e');
    return false;
  }
}

Future<Map<bool, Client?>> createClient(BuildContext context) async {
  try {
    final clientProvider = context.read<ClientProvider>();
    final constantInfoProvider = context.read<ClientConstantInfoProvider>();
    final diseaseProvider = context.read<DiseaseProvider>();
    final cmfuProvider = context.read<ClientMonthlyFollowUpProvider>();
    final preferredFoodsProvider = context.read<PreferredFoodsProvider>();
    final weightAreasProvider = context.read<WeightAreasProvider>();
    final visitProvider = context.read<VisitProvider>();

    if (await clientProvider.isPhoneNumUsed(ClientRegistrationTEC.phoneController.text)) {
      if (!context.mounted) return {false: null};
      showMySnackBar(context, 'هذا الرقم مستخدم بالفعل', Colors.red);
      return {false: null};
    }

    Client c = Client(
        clientId: '',
        name: ClientRegistrationTEC.nameController.text.toLowerCase(),
        clientPhoneNum: ClientRegistrationTEC.phoneController.text,
        birthdate: (() {
          final birthYearText =
              ClientRegistrationTEC.birthYearController.text.trim();
          final parsedYear = int.tryParse(birthYearText);
          if (parsedYear == null) return null;
          return DateTime(parsedYear, 12, 31);
        })(),
        diet: ClientRegistrationTEC.dietController.text,
        plat: ClientRegistrationTEC.platControllers
            .map((e) => double.tryParse(e.text) ?? 0.0)
            .toList(),
        height:
            double.tryParse(ClientRegistrationTEC.heightController.text) ?? 0.0,
        weight:
            double.tryParse(ClientRegistrationTEC.weightController.text) ?? 0.0,
        subscriptionType: getSubscriptionTypeFromString(
            ClientRegistrationTEC.subscriptionTypeController.text),
        notes: ClientRegistrationTEC.notesController.text,
        gender:
            getGenderFromString(ClientRegistrationTEC.genderController.text),
        lastVisitId: '',
        clientConstantInfoId: '',
        diseaseId: '',
        clientLastMonthlyFollowUpId: '',
        preferredFoodsId: '',
        weightAreasId: '');

    await clientProvider.createClient(c); // client ID is generated here

    c.mClientConstantInfoId =
        await createClientConstantInfo(c.mClientId, constantInfoProvider) ?? '';
    c.mDiseaseId = await createDisease(c.mClientId, diseaseProvider) ?? '';
    final cmfuId = await createClientMonthlyFollowUp(c, cmfuProvider) ?? '';
    c.mClientLastMonthlyFollowUpId = cmfuId.isNotEmpty ? cmfuId : '';
    c.mPreferredFoodsId =
        await createPreferredFoods(c.mClientId, preferredFoodsProvider) ?? '';
    c.mWeightAreasId = await createWeightAreas(c.mClientId, weightAreasProvider) ?? '';

    if (NewVisitTEC.clientVisits.isNotEmpty) {
      c.mLastVisitId = getLatestVisitId();
      for (Visit v in NewVisitTEC.clientVisits) {
        v.mClientId = c.mClientId;
        if (c.mHeight != null && c.mHeight! > 0 && v.mWeight > 0) {
          v.mBMI = normalizeBmi(v.mWeight / ((c.mHeight! / 100) * (c.mHeight! / 100)));
        } else {
          v.mBMI = 0.0;
        }
        await visitProvider.updateVisit(v);
      }
    }
    // c.lastVisitId = getLatestVisitId() ?? '';

    // only after you add all extra IDs to the client object
    await clientProvider.updateClient(c); // Update the client with new IDs
    c.printClientInfo();
    return {true: c};
  } catch (e) {
    mDebug('Error creating client: $e');
    return {false: null};
  }
}

Future<String?> createDisease(String clientId, DiseaseProvider provider) async {
  try {
    Disease d = Disease(
      diseaseId: '',
      clientId: clientId,
      hypertension:
          ClientRegistrationTEC.hypertensionController.text.toLowerCase() ==
              'true',
      hypotension:
          ClientRegistrationTEC.hypotensionController.text.toLowerCase() ==
              'true',
      vascular:
          ClientRegistrationTEC.vascularController.text.toLowerCase() == 'true',
      anemia:
          ClientRegistrationTEC.anemiaController.text.toLowerCase() == 'true',
      otherHeart: ClientRegistrationTEC.otherHeartController.text,
      colon: ClientRegistrationTEC.colonController.text.toLowerCase() == 'true',
      constipation:
          ClientRegistrationTEC.constipationController.text.toLowerCase() ==
              'true',
      familyHistoryDM:
          ClientRegistrationTEC.familyHistoryDMController.text.toLowerCase() ==
              'true',
      previousOBMed:
          ClientRegistrationTEC.previousOBMedController.text.toLowerCase() ==
              'true',
      previousOBOperations: ClientRegistrationTEC
              .previousOBOperationsController.text
              .toLowerCase() ==
          'true',
      renal: ClientRegistrationTEC.renalController.text,
      liver: ClientRegistrationTEC.liverController.text,
      git: ClientRegistrationTEC.gitController.text,
      endocrine: ClientRegistrationTEC.endocrineController.text,
      rheumatic: ClientRegistrationTEC.rheumaticController.text,
      allergies: ClientRegistrationTEC.allergiesController.text,
      neuro: ClientRegistrationTEC.neuroController.text,
      psychiatric: ClientRegistrationTEC.psychiatricController.text,
      otherDiseases: ClientRegistrationTEC.otherDiseaseController.text,
      hormonal: ClientRegistrationTEC.hormonalController.text,
    );

    await provider.createDisease(d);
    d.printDisease();

    return d.mDiseaseId;
  } catch (e) {
    mDebug('Error creating disease: $e');
    return null;
  }
}

Future<String?> createClientMonthlyFollowUp(
    Client client, ClientMonthlyFollowUpProvider provider) async {
  try {
    double bmi = 0.0;
    if (client.mHeight != null && client.mWeight != null && client.mHeight! > 0) {
      bmi = normalizeBmi(client.mWeight! / ((client.mHeight! / 100) * (client.mHeight! / 100)));
    }
    ClientMonthlyFollowUp cmfu = ClientMonthlyFollowUp(
      clientId: client.mClientId,
      clientMonthlyFollowUpId: '',
      bmi: bmi,
      pbf: double.tryParse(ClientRegistrationTEC.pbfController.text) ?? 0.0,
      water: ClientRegistrationTEC.waterController.text,
      maxWeight:
          double.tryParse(ClientRegistrationTEC.maxWeightController.text) ??
              0.0,
      optimalWeight:
          double.tryParse(ClientRegistrationTEC.optimalWeightController.text) ??
              0.0,
      bmr: double.tryParse(ClientRegistrationTEC.bmrController.text) ?? 0.0,
      maxCalories:
          double.tryParse(ClientRegistrationTEC.maxCaloriesController.text) ??
              0.0,
      dailyCalories:
          double.tryParse(ClientRegistrationTEC.dailyCaloriesController.text) ??
              0.0,
      muscleMass:
          double.tryParse(ClientRegistrationTEC.muscleMassController.text) ?? 0.0,
      date: DateTime.now(),
      notes: '',
    );

    await provider.createClientMonthlyFollowUp(cmfu);
    cmfu.printClientMonthlyFollowUp();

    return cmfu.mClientMonthlyFollowUpId;
  } catch (e) {
    mDebug('Error creating client monthly follow-up: $e');
    return null;
  }
}

Future<String?> createClientConstantInfo(
    String clientId, ClientConstantInfoProvider provider) async {
  try {
    ClientConstantInfo cci = ClientConstantInfo(
      clientId: clientId,
      clientConstantInfoId: '',
      area: ClientRegistrationTEC.areaController.text,
      activityLevel: getActivityLevelFromString(
          ClientRegistrationTEC.activityLevelController.text),
      YOYO: ClientRegistrationTEC.yoyoController.text.toLowerCase() == 'true',
      sports:
          ClientRegistrationTEC.sportsController.text.toLowerCase() == 'true',
    );

    await provider.createClientConstantInfo(cci);
    cci.printClientConstantInfo();

    return cci.mClientConstantInfoId;
  } catch (e) {
    mDebug('Error creating client constant info: $e');
    return null;
  }
}

Future<String?> createPreferredFoods(
    String clientId, PreferredFoodsProvider provider) async {
  try {
    PreferredFoods pf = PreferredFoods(
      preferredFoodsId: '',
      clientId: clientId,
      carbohydrates:
          ClientRegistrationTEC.carbohydratesController.text.toLowerCase() ==
              'true',
      protein:
          ClientRegistrationTEC.proteinController.text.toLowerCase() == 'true',
      dairy: ClientRegistrationTEC.dairyController.text.toLowerCase() == 'true',
      veg: ClientRegistrationTEC.vegController.text.toLowerCase() == 'true',
      fruits:
          ClientRegistrationTEC.fruitsController.text.toLowerCase() == 'true',
      others: ClientRegistrationTEC.otherPreferredFoodsController.text,
    );

    await provider.createPreferredFoods(pf);
    pf.printPreferredFoods();

    return pf.mPreferredFoodsId;
  } catch (e) {
    mDebug('Error creating preferred foods: $e');
    return null;
  }
}

Future<String?> createWeightAreas(String clientId, WeightAreasProvider provider) async {
  try {
    WeightAreas wa = WeightAreas(
      weightAreasId: '',
      clientId: clientId,
      abdomen:
          ClientRegistrationTEC.abdomenController.text.toLowerCase() == 'true',
      buttocks:
          ClientRegistrationTEC.buttocksController.text.toLowerCase() == 'true',
      waist: ClientRegistrationTEC.waistController.text.toLowerCase() == 'true',
      thighs:
          ClientRegistrationTEC.thighsController.text.toLowerCase() == 'true',
      arms: ClientRegistrationTEC.armsController.text.toLowerCase() == 'true',
      breast:
          ClientRegistrationTEC.breastController.text.toLowerCase() == 'true',
      back: ClientRegistrationTEC.backController.text.toLowerCase() == 'true',
    );

    await provider.createWeightAreas(wa);
    wa.printWeightAreas();

    return wa.mWeightAreasId;
  } catch (e) {
    mDebug('Error creating weight areas: $e');
    return null;
  }
}
