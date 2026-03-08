class TurnResponse {
  final String text;
  final String? audioUrl;
  final List<ActionItem>? actionItems;

  TurnResponse({
    required this.text,
    this.audioUrl,
    this.actionItems,
  });

  factory TurnResponse.fromJson(Map<String, dynamic> json) {
    return TurnResponse(
      text: json['text'] as String,
      audioUrl: json['audioUrl'] as String?,
      actionItems: (json['actionItems'] as List?)
          ?.map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'audioUrl': audioUrl,
    'actionItems': actionItems?.map((e) => e.toJson()).toList(),
  };
}

class ActionItem {
  final String label;
  final String type;
  final String? payload;

  ActionItem({
    required this.label,
    required this.type,
    this.payload,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      label: json['label'] as String,
      type: json['type'] as String,
      payload: json['payload'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'type': type,
    'payload': payload,
  };
}
