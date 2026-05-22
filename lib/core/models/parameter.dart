class Parameter {
  const Parameter({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Parameter.fromJson(Map<String, Object?> json) {
    return Parameter(
      name: (json['name'] as String? ?? '').trim(),
      amount: _readAmount(json['amount']),
      unit: (json['unit'] as String? ?? '').trim(),
    );
  }

  final String name;
  final double amount;
  final String unit;

  Parameter copyWith({String? name, double? amount, String? unit}) {
    return Parameter(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }

  Parameter scaledBy(int multiplier) {
    if (multiplier < 1 || multiplier > 99) {
      throw RangeError.range(multiplier, 1, 99, 'multiplier');
    }

    return copyWith(amount: amount * multiplier);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'name': name, 'amount': amount, 'unit': unit};
  }

  String get formattedAmount {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static double _readAmount(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Parameter amount must be numeric: $value');
  }
}
