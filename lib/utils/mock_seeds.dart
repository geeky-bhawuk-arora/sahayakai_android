import '../models/chat_message.dart';
import 'package:uuid/uuid.dart';

class SahayakMockSeeds {
  static List<ChatMessage> generate150Messages() {
    final List<ChatMessage> messages = [];
    final uuid = const Uuid();
    final now = DateTime.now();

    for (int i = 0; i < 150; i++) {
      final isBot = i % 2 != 0;
      final timestamp = now.subtract(Duration(minutes: 150 - i));
      
      String content;
      MessageType type = MessageType.text;
      List<String>? actions;

      if (i < 50) {
        // General scheme queries
        if (!isBot) {
          content = i % 4 == 0 ? "What is PM-KISAN?" : "Tell me about MGNREGA benefits.";
        } else {
          content = i % 4 == 0 
            ? "# PM-KISAN\nPradhan Mantri Kisan Samman Nidhi is an initiative by the Government of India in which all farmers get up to ₹6,000 per year as minimum income support."
            : "# MGNREGA\nThe Mahatma Gandhi National Rural Employment Guarantee Act provides at least 100 days of guaranteed wage employment in a financial year.";
        }
      } else if (i < 100) {
        // Eligibility check interactions
        if (!isBot) {
          content = i % 4 == 0 ? "Am I eligible for PM-KISAN?" : "Why was my application rejected?";
        } else {
          content = i % 4 == 0 
            ? "Based on your profile, you are **Eligible**. However, you need to link your Aadhaar card."
            : "Your application is pending because of **Missing Bank Details**. Please update your passbook photo.";
          actions = i % 4 == 0 ? ["Link Aadhaar", "View Documents"] : ["Update Bank", "Contact Support"];
        }
      } else {
        // Voice-to-text transcriptions
        if (!isBot) {
          content = i % 4 == 0 ? "मुझे नई योजनाओं के बारे में बताएं" : "Show me schemes for senior citizens.";
          type = i % 3 == 0 ? MessageType.voice : MessageType.text;
        } else {
          content = i % 4 == 0 
            ? "यहाँ आपके लिए कुछ नई योजनाएं हैं:\n1. अटल पेंशन योजना\n2. प्रधानमंत्री सुरक्षा बीमा योजना"
            : "For senior citizens, we recommend the **Pradhan Mantri Vaya Vandana Yojana** which provides a guaranteed rate of return.";
        }
      }

      messages.add(ChatMessage(
        id: uuid.v4(),
        content: content,
        type: type,
        sender: isBot ? MessageSender.bot : MessageSender.user,
        timestamp: timestamp,
        actionItems: actions,
      ));
    }

    return messages;
  }
}
