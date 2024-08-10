import 'dart:io';
import 'package:dotenv/dotenv.dart' show load, env;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class Prediction {
  String url = "";
  Prediction(url) {
    this.url = url;
  }

  Future<String> result() async {
    load();
    String? apiKey = env['GEMINI_API_KEY'];
    String? bucketName = env['BUCKET_NAME'];
    String? googleProjectId = env['GOOGLE_PROJECT_ID'];
    String? googleProjectRegion = env['GOOGLE_PROJECT_REGION'];

    if (apiKey == null) {
      stderr.writeln(r'No $GEMINI_API_KEY environment variable');
      exit(1);
    }

    if (bucketName == null) {
      stderr.writeln(r'No $BUCKET_NAME environment variable');
      exit(1);
    }

    if (googleProjectRegion == null) {
      stderr.writeln(r'No $GOOGLE_PROJECT_ID environment variable');
      exit(1);
    }

    if (googleProjectId == null) {
      stderr.writeln(r'No $GOOGLE_PROJECT_REGION environment variable');
      exit(1);
    }
/*
    var credentials = ServiceAccountCredentials.fromJson(
      File('service.json').readAsStringSync(),
    );

    const scopes = [storage.StorageApi.devstorageFullControlScope];

    var client = await clientViaServiceAccount(credentials, scopes);

    final accessToken = await client.credentials.accessToken.data;

    var storageApi = storage.StorageApi(client);

    final image = await http.get(Uri.parse(this.url));
    final objectName = 'image-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = "./web/images/${objectName}";

    if (image.statusCode != 200) {
      return 'Error downloading image: ${image.statusCode}';
    }

    final imageFile = File(filePath);
    await imageFile.writeAsBytes(image.bodyBytes);

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final requestPayload = {
      'instances': [
        {
          'prompt': {
            'text': 'Describe this image.',
            'image': {
              'mimeType': 'image/jpeg', // Or the appropriate MIME type
              'imageBytes': base64Image,
            },
          },
        },
      ],
      'parameters': {
        // Add any additional parameters required by the model
      },
    };

    final apiEndpoint =
        'https://$googleProjectRegion-aiplatform.googleapis.com/v1/projects/$googleProjectId/locations/$googleProjectRegion/publishers/google/models/gemini-1.5-flash:predict';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: headers,
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response: $responseData');
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending request to Vertex AI: $e');
    }


    final media = storage.Media(imageFile.openRead(), imageFile.lengthSync());
    await storageApi.objects.insert(
      storage.Object()..name = objectName,
      bucketName,
      uploadMedia: media,
    );

    final imageUrl = 'https://storage.googleapis.com/$bucketName/$objectName';

    print(imageUrl);

    */
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 2,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 1024,
        responseMimeType: 'text/plain',
      ),
    );

    final chat = model.startChat(history: []);
    final message =
        'Analyze the following base64 image and check whether it shows carbon emission activities:';
    final content = Content.text(message);
    final response = await chat.sendMessage(content);
    print(response.text);
    return response.text ?? "";
  }
}
