import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:window_manager/window_manager.dart';

import '../Core/Services/DebugLoggerService.dart';
import '../Core/View/PopUps/MyAlertDialogue.dart';

class UpdateService {
  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isUpdateInProgress = false;

  Future<void> checkForUpdates(BuildContext context) async {
    if (_isUpdateInProgress) {
      mDebug('Shorebird: Update check already in progress. Skipping.');
      return;
    }

    _isUpdateInProgress = true;
    try {
      final status = await _updater.checkForUpdate();
      if (!context.mounted) return;
      mDebug('Shorebird update status: $status');

      if (status == UpdateStatus.restartRequired) {
        mDebug('Shorebird: Update already downloaded. Restarting to apply...');
        if (context.mounted) {
          await showAlertDialogue(
            context: context,
            title: 'تحديث جاهز',
            content:
                'تم تنزيل التحديث وهو جاهز الآن.\nيرجى إعادة تشغيل التطبيق لتطبيق التحديث.',
            buttonText: 'إغلاق البرنامج',
            returnText: '', // Empty means no cancellation, forced restart
            onPressed: () async {
              await _restartApp();
            },
          );
        }
        return;
      }

      if (status == UpdateStatus.outdated) {
        if (!context.mounted) return;

        // Show the initial alert dialogue informing about the update
        await showAlertDialogue(
          context: context,
          title: 'تحديث متاح',
          content:
              'هناك تحديث جديد. سيتم تنزيله وتثبيته الآن لضمان عمل التطبيق بشكل سليم.',
          buttonText: 'تأكيد',
          returnText: '', // No return text forces the user to accept
          onPressed: () async {
            // Let it pop normally
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));
        if (!context.mounted) return;

        // Show a blocking progress dialog immediately while downloading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: Colors.blue[50]!,
              title: const Text('جاري تنزيل التحديث', textAlign: TextAlign.end),
              content: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'يرجى الانتظار حتى يكتمل التنزيل...',
                      textAlign: TextAlign.end,
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          ),
        );

        try {
          mDebug('Shorebird update() starting...');
          await _updater.update();
          mDebug('Shorebird update() completed');
        } finally {
          // Dismiss the progress dialog
          if (context.mounted) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
            } catch (_) {}
          }
        }

        if (!context.mounted) return;
        final isDesktop =
            !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows);
        await showAlertDialogue(
          context: context,
          title: 'تم التنزيل',
          content: 'تم تنزيل التحديث. يجب إعادة تشغيل البرنامج الآن لتطبيقه.',
          buttonText: isDesktop ? 'إغلاق البرنامج' : 'إغلاق التطبيق',
          returnText: '', // Forced to close
          onPressed: () async {
            await _restartApp();
          },
        );
      }
    } on UpdateException catch (e) {
      if (e.message.contains('in progress')) {
        mDebug(
            'Shorebird: Update is downloading in background. Ignoring exception.');
        return;
      }

      if (context.mounted) {
        await showAlertDialogue(
          context: context,
          title: 'تعذر إكمال التحديث',
          content: 'حدث خطأ أثناء تنزيل التحديث. برجاء المحاولة لاحقًا.\n$e',
          buttonText: 'حسنًا',
          returnText: '',
          onPressed: () async {},
        );
      }
      mDebug('Shorebird UpdateException (Logged): $e');
    } catch (e) {
      mDebug('Unexpected error in Shorebird checkForUpdates: $e');
    } finally {
      _isUpdateInProgress = false;
    }
  }

  Future<void> _restartApp() async {
    mDebug('Shorebird: Restarting app to apply update...');
    final isDesktop =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows);
    if (isDesktop) {
      try {
        await Process.start(
          Platform.resolvedExecutable,
          Platform.executableArguments,
          mode: ProcessStartMode.detached,
        );
      } catch (e) {
        mDebug('Failed to restart app via process spawn: $e');
      }
      await windowManager.close();
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> initPatch() async {
    final patch = await _updater.readCurrentPatch();
    mDebug('Shorebird current patch: ${patch?.number}');
  }

  Future<int?> getPatchVersion() async {
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      // Handle error if any, e.g. no patch installed
      mDebug('Error getting patch version: $e');
      return null;
    }
  }
}
