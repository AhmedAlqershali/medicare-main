import 'package:flutter/material.dart';

import '../auth/models/medical_catalog_entry.dart';

class SearchableCatalogField extends StatelessWidget {
  const SearchableCatalogField({
    super.key,
    required this.label,
    required this.entries,
    required this.selectedId,
    required this.onChanged,
    this.legacyValue,
  });

  final String label;
  final List<MedicalCatalogEntry> entries;
  final String? selectedId;
  final ValueChanged<MedicalCatalogEntry?> onChanged;
  final String? legacyValue;

  @override
  Widget build(BuildContext context) {
    final selected = entries.where((entry) => entry.id == selectedId).firstOrNull;
    final display = selected?.displayName ??
        (legacyValue?.trim().isNotEmpty == true ? legacyValue!.trim() : 'اختر من الدليل');
    return InkWell(
      onTap: () async {
        final chosen = await showDialog<MedicalCatalogEntry>(
          context: context,
          builder: (_) => _CatalogSearchDialog(entries: entries, label: label),
        );
        if (chosen != null) onChanged(chosen);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.medical_information_outlined),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(display),
      ),
    );
  }
}

class _CatalogSearchDialog extends StatefulWidget {
  const _CatalogSearchDialog({required this.entries, required this.label});

  final List<MedicalCatalogEntry> entries;
  final String label;

  @override
  State<_CatalogSearchDialog> createState() => _CatalogSearchDialogState();
}

class _CatalogSearchDialogState extends State<_CatalogSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.entries.where((entry) =>
        query.isEmpty ||
        entry.nameAr.toLowerCase().contains(query) ||
        entry.nameEn.toLowerCase().contains(query));
    return AlertDialog(
      title: Text(widget.label),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              labelText: 'بحث',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد عناصر مطابقة.'))
                : ListView(
                    children: [
                      for (final entry in filtered)
                        ListTile(
                          title: Text(entry.displayName),
                          subtitle: entry.nameEn.isEmpty ? null : Text(entry.nameEn),
                          onTap: () => Navigator.pop(context, entry),
                        ),
                    ],
                  ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      ],
    );
  }
}
