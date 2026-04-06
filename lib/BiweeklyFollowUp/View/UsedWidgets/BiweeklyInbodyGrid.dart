import 'package:flutter/material.dart';

import '../../../Core/Controller/UtilityFunctions.dart';
import '../../../Core/Model/Classes/Client.dart';
import '../../../Core/Model/Classes/ClientMonthlyFollowUp.dart';
import '../../Model/InbodyModels.dart';
import 'InbodyRowsBuilder.dart';

class BiweeklyInbodyGrid extends StatelessWidget {
  final Client client;
  final List<ClientMonthlyFollowUp> previousFollowUps;

  const BiweeklyInbodyGrid({
    super.key,
    required this.client,
    required this.previousFollowUps,
  });

  // Neutral arrow color
  static const Color _arrowColor = Color(0xFF78909C); // blueGrey[400]
  static const Color _headerBg = Color(0xFFE3F2FD); // blue[50]
  static const Color _zebraStripe = Color(0xFFF5F9FF);

  @override
  Widget build(BuildContext context) {
    final List<InbodyColumn> previousColumns = _preparePreviousColumns();
    final List<InbodyAttribute> attributes = buildInbodyAttributes(client);

    // Total columns = label + previous columns + today
    final int totalCols = 1 + previousColumns.length + 1;

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            child: const Text(
              'نتائج الانبدي السابقة والحالية',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Table content — uses a real Table so all cells align in columns
          Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48,
                ),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: _buildColumnWidths(totalCols),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey[200]!,
                      width: 0.5,
                    ),
                  ),
                  children: [
                    _buildHeaderRow(previousColumns),
                    ...attributes.asMap().entries.map((entry) {
                      return _buildDataRow(
                        entry.value,
                        previousColumns,
                        isEven: entry.key.isEven,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int totalCols) {
    final Map<int, TableColumnWidth> widths = {};
    // All columns get flexible width
    for (int i = 0; i < totalCols; i++) {
      widths[i] = const FlexColumnWidth();
    }
    return widths;
  }

  List<InbodyColumn> _preparePreviousColumns() {
    final List<ClientMonthlyFollowUp> sortedAsc = [...previousFollowUps];
    sortedAsc.sort((a, b) {
      final da = a.mDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.mDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });

    final List<InbodyColumn> columns = [];
    if (sortedAsc.isNotEmpty) {
      columns
          .add(InbodyColumn(title: 'الانبدي الاول', followUp: sortedAsc.first));
    }

    if (sortedAsc.length > 2) {
      final secondToLast = sortedAsc[sortedAsc.length - 2];
      if (!columns.any((c) =>
          c.followUp.mClientMonthlyFollowUpId ==
          secondToLast.mClientMonthlyFollowUpId)) {
        columns.add(InbodyColumn(
            title: 'الانبدي القبل الاخير', followUp: secondToLast));
      }
    }

    if (sortedAsc.length > 1) {
      final last = sortedAsc.last;
      if (!columns.any((c) =>
          c.followUp.mClientMonthlyFollowUpId ==
          last.mClientMonthlyFollowUpId)) {
        columns
            .add(InbodyColumn(title: 'الانبدي الاخير', followUp: last));
      }
    }
    return columns;
  }

  TableRow _buildHeaderRow(List<InbodyColumn> previousColumns) {
    return TableRow(
      decoration: BoxDecoration(color: _headerBg),
      children: [
        _buildHeaderCell('البند'),
        ...previousColumns.map((col) => _buildHistoricalHeaderCell(col)),
        _buildHeaderCell('اليوم'),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF1565C0),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHistoricalHeaderCell(InbodyColumn col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        children: [
          Text(
            col.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1565C0),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              getDateText(col.followUp.mDate),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF546E7A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildDataRow(
    InbodyAttribute row,
    List<InbodyColumn> previousColumns, {
    required bool isEven,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : _zebraStripe,
      ),
      children: [
        _buildLabelCell(row.label),
        ...previousColumns.asMap().entries.map((entry) {
          final colIndex = entry.key;
          final col = entry.value;
          final currentValue = row.getPreviousValue(col.followUp);

          // Determine the previous column's value for arrow comparison
          String? previousValue;
          if (colIndex > 0) {
            previousValue = row
                .getPreviousValue(previousColumns[colIndex - 1].followUp);
          }

          return _buildValueCellWithArrow(currentValue, previousValue);
        }),
        // Today column — consistent padding for both input fields and text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Center(child: row.todayWidget),
        ),
      ],
    );
  }

  Widget _buildLabelCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF37474F),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildValueCellWithArrow(String value, String? previousValue) {
    // Parse numeric values for comparison
    final double? current = _parseNumeric(value);
    final double? previous =
        previousValue != null ? _parseNumeric(previousValue) : null;

    Widget? arrowWidget;
    if (current != null && previous != null && current != previous) {
      final isUp = current > previous;
      arrowWidget = Icon(
        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        size: 14,
        color: _arrowColor,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF455A64)),
              textAlign: TextAlign.center,
            ),
          ),
          if (arrowWidget != null) ...[
            const SizedBox(width: 4),
            arrowWidget,
          ],
        ],
      ),
    );
  }

  /// Tries to extract a numeric value from a display string.
  /// Handles values like "74.8", "12.4 %", "85 كجم", etc.
  double? _parseNumeric(String text) {
    if (text.isEmpty || text == '-') return null;
    // Remove common suffixes and whitespace
    final cleaned = text
        .replaceAll('%', '')
        .replaceAll('كجم', '')
        .replaceAll(RegExp(r'[^\d.\-]'), '')
        .trim();
    return double.tryParse(cleaned);
  }
}
