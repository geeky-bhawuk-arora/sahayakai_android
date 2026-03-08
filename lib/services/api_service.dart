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

  Future<Map<String, dynamic>> checkEligibility(String schemeId) async {
    final response = await _dio.get('/schemes/$schemeId/eligibility');
    return response.data;
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
          'text': '# PM-KISAN Eligibility\n\nYou are eligible for **PM-KISAN**. \n\n### Benefits:\n- ₹2,000 every 4 months\n- Direct Bank Transfer\n\n### Required Actions:\nPlease ensure your Aadhar is linked to your bank account.',
          'audioUrl': 'https://example.com/mock-audio.mp3',
          'actionItems': [
            {'label': 'Link Aadhar', 'type': 'navigate', 'payload': 'link-aadhar'},
            {'label': 'View Documents', 'type': 'form', 'payload': 'view-docs'},
          ],
        },
        statusCode: 200,
      ));
    } else if (options.path.contains('/eligibility')) {
      handler.resolve(Response(
        requestOptions: options,
        data: {
          'eligible': true,
          'confidence_score': 0.95,
          'missing_documents': ['Land Possession Certificate'],
          'message': 'You meet most criteria, but need to upload one document.'
        },
        statusCode: 200,
      ));
    } else {
      handler.next(options);
    }
  }
}
