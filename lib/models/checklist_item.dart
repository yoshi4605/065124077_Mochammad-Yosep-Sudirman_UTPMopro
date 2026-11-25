/// Model untuk item Tas Siaga Bencana (Checklist)
class ChecklistItem {
  final int? id;
  final String item;
  final String category;
  final bool isChecked;

  const ChecklistItem({
    this.id,
    required this.item,
    required this.category,
    this.isChecked = false,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()),
      item: map['item']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Lainnya',
      isChecked: (map['is_checked'] == 1 || map['is_checked'] == true),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'item': item,
      'category': category,
      'is_checked': isChecked ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  ChecklistItem copyWith({
    int? id,
    String? item,
    String? category,
    bool? isChecked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      item: item ?? this.item,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
