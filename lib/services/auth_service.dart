import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  /// Registers a user
  Future<Map<String, dynamic>> register({
    required String name,
    required String schoolEmail,
    required String otherEmail,
    required String matricule,
    required String password,
    required String gender,
    File? profileImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/register');

      http.Response response;

      // If image is selected, use multipart request
      if (profileImage != null) {
        var request = http.MultipartRequest('POST', uri);

        request.fields['name'] = name;
        request.fields['school_email'] = schoolEmail;
        request.fields['other_email'] = otherEmail;
        request.fields['matricule'] = matricule;
        request.fields['password'] = password;
        request.fields['gender'] = gender;

        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );

        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Otherwise, send JSON
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': name,
            'school_email': schoolEmail,
            'other_email': otherEmail,
            'matricule': matricule,
            'password': password,
            'gender': gender,
          }),
        );
      }

      // Check response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to register: ${response.body}');
        }
        throw HttpException(
          'Failed to register. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in AuthService.register: $e');
      }
      rethrow;
    }
  }
}
