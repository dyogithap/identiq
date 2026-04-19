import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_document.dart';

class DocumentAIService {
  static const String _projectId = 'YOUR_PROJECT_ID';
  static const String _location = 'YOUR_LOCATION';
  static const String _processorId = 'YOUR_PROCESSOR_ID';

  // IMPORTANT: This should be OAuth access token (not API key)
  static const String _accessToken = 'YOUR_ACCESS_TOKEN';

  static final String _endpointUrl =
      'https://$_location-documentai.googleapis.com/v1/projects/$_projectId/locations/$_location/processors/$_processorId:process';

  Future<UserDocument> processDocument(File imageFile) async {
    try {
      final base64Image = await _encodeFileToBase64(imageFile);
      final mimeType = _getMimeType(imageFile);

      final headers = {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        "rawDocument": {
          "content": base64Image,
          "mimeType": mimeType,
        }
      });

      final response = await http.post(
        Uri.parse(_endpointUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw HttpException(
            'Failed: ${response.statusCode} ${response.body}');
      }

      final Map<String, Object?> jsonResponse =
          jsonDecode(response.body);

      return _parseResponse(jsonResponse);
    } on SocketException {
      throw Exception('Network error');
    } catch (e) {
      throw Exception('Error processing document: $e');
    }
  }

  // ---------- Helpers ----------

  Future<String> _encodeFileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  String _getMimeType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  UserDocument _parseResponse(Map<String, Object?> json) {
    final document = json['document'] as Map<String, Object?>?;
    if (document == null) {
      throw const FormatException('Missing document field');
    }

    final extractedText = document['text'] as String? ?? '';

    final entities = (document['entities'] as List?) ?? [];

    final name = _getEntity(entities, ['person_name']) ?? 'Unknown';
    final docType = _getEntity(entities, ['document_type']) ?? 'ID Document';
    final id = _getEntity(entities, ['document_number']) ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final expiryStr = _getEntity(entities, ['expiry_date']);
    final expiryDate = DateTime.tryParse(expiryStr ?? '') ??
        DateTime.now(); // fallback = today

    final confidence = _averageConfidence(entities);

    return UserDocument(
      id: id,
      name: name,
      documentType: docType,
      expiryDate: expiryDate,
      extractedText: extractedText,
      confidenceScore: confidence,
    );
  }

  String? _getEntity(List entities, List<String> possibleTypes) {
    for (final e in entities) {
      final entity = e as Map;
      final type = entity['type']?.toString();

      if (possibleTypes.contains(type)) {
        return entity['mentionText']?.toString();
      }
    }
    return null;
  }

  double _averageConfidence(List entities) {
    double sum = 0;
    int count = 0;

    for (final e in entities) {
      final entity = e as Map;
      final conf = entity['confidence'];

      if (conf != null) {
        sum += (conf as num).toDouble();
        count++;
      }
    }

    return count == 0 ? 0.0 : sum / count;
  }
}