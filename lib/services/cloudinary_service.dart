import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // ✅ Confirmed cloud name
  static const String cloudName = "dblfdal0u";

  // ✅ Your presets (exact names you created in Cloudinary)
  static const String artworkPreset = "artiva_unsigned";
  static const String exhibitionPreset = "exhibitions_unsigned";

  // ✅ NEW: Profile preset (create this in Cloudinary as UNSIGNED)
  static const String profilePreset = "profiles_unsigned";

  // ✅ Your folders (keeps Cloudinary organized)
  static const String artworkFolder = "artworks";
  static const String exhibitionFolder = "exhibitions";

  // ✅ NEW: Profile folder
  static const String profileFolder = "profiles";

  /// Uploads an image to Cloudinary and returns the secure_url.
  ///
  /// Usage:
  ///   - For artworks:     uploadArtworkImage(file: File(path))
  ///   - For exhibitions: uploadExhibitionImage(file: File(path))
  ///   - For profile:     uploadProfileImage(file: File(path))
  ///
  /// If you want custom preset/folder, call uploadImageRaw().
  static Future<String> uploadArtworkImage({required File file}) {
    return uploadImageRaw(
      file: file,
      uploadPreset: artworkPreset,
      folder: artworkFolder,
    );
  }

  static Future<String> uploadExhibitionImage({required File file}) {
    return uploadImageRaw(
      file: file,
      uploadPreset: exhibitionPreset,
      folder: exhibitionFolder,
    );
  }

  // ✅ NEW: Profile image uploader
  static Future<String> uploadProfileImage({required File file}) {
    return uploadImageRaw(
      file: file,
      uploadPreset: profilePreset,
      folder: profileFolder,
    );
  }

  /// Lowest-level uploader. Use only if you need custom preset/folder.
  static Future<String> uploadImageRaw({
    required File file,
    required String uploadPreset,
    String? folder,
    String? publicId, // optional
  }) async {
    if (!await file.exists()) {
      throw Exception("Selected image file not found. Pick again.");
    }

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset;

    if (folder != null && folder.trim().isNotEmpty) {
      request.fields["folder"] = folder.trim();
    }

    // Optional: only if you want to set your own public id.
    // (Your presets may disallow custom public id, so keep this null unless enabled.)
    if (publicId != null && publicId.trim().isNotEmpty) {
      request.fields["public_id"] = publicId.trim();
    }

    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw Exception("Network error while uploading image: $e");
    }

    final body = await streamed.stream.bytesToString();

    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception("Cloudinary upload failed: Invalid response: $body");
    }

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final msg = data["error"]?["message"]?.toString() ?? body;
      throw Exception("Cloudinary upload failed: $msg");
    }

    final url = (data["secure_url"] ?? "").toString().trim();
    if (url.isEmpty) {
      throw Exception("Cloudinary upload failed: secure_url missing");
    }

    return url;
  }

  /// Optional helper: delete an uploaded asset by public_id.
  /// NOTE: This requires signed requests (API secret) -> NOT usable with unsigned-only setup.
  static Future<void> deleteNotSupportedInUnsigned() async {
    throw Exception("Delete requires signed API calls; unsigned preset cannot delete.");
  }
}
