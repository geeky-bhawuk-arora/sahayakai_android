import 'package:json_annotation/json_annotation.dart';

part 'turn_response.g.dart';

@JsonSerializable()
class TurnResponse {
  final String text;
  final String? audioUrl;
  final List<ActionItem>? actionItems;

  TurnResponse({
    required this.text,
    this.audioUrl,
    this.actionItems,
  });

  factory TurnResponse.fromJson(Map<String, dynamic> json) => _$TurnResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TurnResponseToJson(this);
}

@JsonSerializable()
class ActionItem {
  final String label;
  final String type; // e.g., 'link', 'navigate', 'form'
  final String? payload;

  ActionItem({
    required this.label,
    required this.type,
    this.payload,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) => _$ActionItemFromJson(json);
  Map<String, dynamic> toJson() => _$ActionItemToJson(this);
}
