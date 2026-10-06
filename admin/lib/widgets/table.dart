import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';

/// Simple read-only data table with a header row of actions.
class ReportTable extends StatelessWidget {
  const ReportTable({super.key, required this.headers, required this.rows, this.onTap});
  final List<String> headers;
  final List<List<Object?>> rows;
  final void Function(int index)? onTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No records')));
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: [for (final h in headers) DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.w800)))],
          rows: [
            for (final (i, r) in rows.indexed)
              DataRow(
                onSelectChanged: onTap == null ? null : (_) => onTap!(i),
                cells: [
                  for (final c in r)
                    DataCell(c is Widget
                        ? c
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(c is DateTime ? formatDateTime(c, locale: 'en') : '${c ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Date range picker button.
class RangeButton extends StatelessWidget {
  const RangeButton({super.key, required this.range, required this.onChanged});
  final DateTimeRange range;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: const Icon(Icons.date_range),
        label: Text('${formatDate(range.start, locale: 'en')} – ${formatDate(range.end, locale: 'en')}'),
        onPressed: () async {
          final r = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: range);
          if (r != null) onChanged(r);
        },
      );
}

bool inRange(DateTime? d, DateTimeRange r) =>
    d != null && !d.isBefore(dateOnly(r.start)) && d.isBefore(dateOnly(r.end).add(const Duration(days: 1)));
