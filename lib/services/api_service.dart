import 'package:dio/dio.dart';
import '../models/scheme.dart';
import '../models/user_profile.dart';
import '../models/turn_response.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<List<Scheme>> getSchemes() async {
    final response = await _dio.get('/schemes');
    return (response.data as List).map((e) => Scheme.fromJson(e)).toList();
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _dio.get('/users/profile');
    return UserProfile.fromJson(response.data);
  }

  Future<void> updateConsent(Map<String, bool> consents) async {
    await _dio.post('/users/consent', data: consents);
  }

  Future<TurnResponse> submitTurn(String voiceUrl) async {
    final response = await _dio.post('/voice/turn', data: {'voice_url': voiceUrl});
    return TurnResponse.fromJson(response.data);
  }
}

class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/schemes') {
      handler.resolve(Response(
        requestOptions: options,
        data: [
          {
            'id': 'pm-kisan-001',
            'name': 'PM-KISAN',
            'description': 'Pradhan Mantri Kisan Samman Nidhi',
            'category': 'Agriculture',
            'benefits': ['₹6,000 per year in three installments'],
            'documentsRequired': ['Aadhar Card', 'Land Records', 'Bank Passbook'],
          },
          {
            'id': 'mgnregs-001',
            'name': 'MGNREGS',
            'description': 'Mahatma Gandhi National Rural Employment Guarantee Scheme',
            'category': 'Employment',
            'benefits': ['100 days of guaranteed wage employment'],
            'documentsRequired': ['Job Card', 'Aadhar Card'],
          }
        ],
        statusCode: 200,
      ));
    } else if (options.path == '/users/profile') {
      handler.resolve(Response(
        requestOptions: options,
        data: {
          'id': 'user-123',
          'name': 'Ramesh Kumar',
          'age': 45,
          'occupation': 'Farmer',
          'annualIncome': 50000.0,
          'hasLand': true,
          'consents': {'data_processing': true, 'scheme_notifications': true},
        },
        statusCode: 200,
      ));
    } else if (options.path == '/voice/turn') {
      handler.resolve(Response(
        requestOptions: options,
        data: {
          'text': 'आप पीएम-किसान योजना के लिए पात्र हैं। (You are eligible for PM-KISAN).',
          'audioUrl': 'https://example.com/mock-audio.mp3',
          'actionItems': [
            {'label': 'आधार कार्ड लिंक करें', 'type': 'navigate', 'payload': 'link-aadhar'},
            {'label': 'बैंक विवरण अपडेट करें', 'type': 'form', 'payload': 'update-bank'},
          ],
        },
        statusCode: 200,
      ));
    } else {
      handler.next(options);
    }
  }
}
