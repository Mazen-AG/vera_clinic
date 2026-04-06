import 'package:flutter/material.dart';
import '../../../Core/Model/Classes/ClientMonthlyFollowUp.dart';

class InbodyColumn {
  final String title;
  final ClientMonthlyFollowUp followUp;

  InbodyColumn({
    required this.title,
    required this.followUp,
  });
}

class InbodyAttribute {
  final String label;
  final String Function(ClientMonthlyFollowUp) previousValueBuilder;
  final Widget todayWidget;

  InbodyAttribute({
    required this.label,
    required this.previousValueBuilder,
    required this.todayWidget,
  });

  String getPreviousValue(ClientMonthlyFollowUp cmfu) {
    return previousValueBuilder(cmfu);
  }
}
