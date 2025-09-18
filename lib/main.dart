import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const TikTokDownloader(),
    );
  }
}

class TikTokDownloader extends StatefulWidget {
  const TikTokDownloader({super.key});

  @override
  State<TikTokDownloader> createState() => _TikTokDownloaderState();
}

class _TikTokDownloaderState extends State<TikTokDownloader> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _status = "";

  Future<void> _downloadVideo() async {
    String url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _status = "Masukkan link TikTok dulu!");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "Sedang memproses...";
    });

    try {
      final response =
          await http.get(Uri.parse("https://www.tikwm.com/api/?url=$url"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String videoUrl = data["data"]["play"] ?? "";

        if (videoUrl.isEmpty) {
          setState(() => _status = "Gagal ambil link video.");
          return;
        }

        // 🔹 Minta izin storage
        var permissionStatus = await Permission.storage.request();
        if (!permissionStatus.isGranted) {
          setState(() => _status = "Izin penyimpanan ditolak.");
          openAppSettings();
          return;
        }

        // 🔹 Download file video
        final videoResponse = await http.get(Uri.parse(videoUrl));

        String customDirPath = "/storage/emulated/0/Video";
        Directory customDir = Directory(customDirPath);

        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }


        String filePath =
            "$customDirPath/tiktok_video_${DateTime.now().millisecondsSinceEpoch}.mp4";

        File file = File(filePath);
        await file.writeAsBytes(videoResponse.bodyBytes);

        setState(() => _status = "✅ Video berhasil diunduh ke: $filePath");
      } else {
        setState(() => _status = "Gagal memproses link.");
      }
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TikTok Downloader")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Masukkan Link TikTok",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              onPressed: _isLoading ? null : _downloadVideo,
              icon: const Icon(Icons.download),
              label: Text(_isLoading ? "Mengunduh..." : "Download"),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
