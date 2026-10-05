enum RuleOperator {
  eq, // Equal
  neq, // Not equal
  gt, // Greater than
  gte, // Greater than or equal
  lt, // Less than
  lte, // Less than or equal
  contains, // For lists (e.g. interests)
  notContains;

  static RuleOperator fromString(String value) {
    return RuleOperator.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RuleOperator.eq,
    );
  }
}

enum RuleType {
  and,
  or,
  condition;

  static RuleType fromString(String value) {
    return RuleType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RuleType.condition,
    );
  }
}

class AccessRule {
  final RuleType type;
  
  // For 'condition' type
  final String? field;
  final RuleOperator? operator;
  final dynamic value;

  // For 'and' / 'or' types
  final List<AccessRule>? conditions;

  AccessRule({
    required this.type,
    this.field,
    this.operator,
    this.value,
    this.conditions,
  });

  factory AccessRule.fromJson(Map<String, dynamic> json) {
    final type = RuleType.fromString(json['type'] ?? 'condition');
    
    if (type == RuleType.condition) {
      return AccessRule(
        type: type,
        field: json['field'],
        operator: RuleOperator.fromString(json['operator'] ?? 'eq'),
        value: json['value'],
      );
    } else {
      final List<dynamic> condJson = json['conditions'] ?? [];
      return AccessRule(
        type: type,
        conditions: condJson.map((e) => AccessRule.fromJson(e)).toList(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    if (type == RuleType.condition) {
      return {
        'type': type.name,
        'field': field,
        'operator': operator?.name,
        'value': value,
      };
    } else {
      return {
        'type': type.name,
        'conditions': conditions?.map((e) => e.toJson()).toList(),
      };
    }
  }
}
