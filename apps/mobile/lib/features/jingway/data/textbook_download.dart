import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/textbook_models.dart';

/// On-demand fetch into app documents `textbooks/` (never APK assets).
class TextbookDownloadService {
  TextbookDownloadService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(minutes: 5),
              headers: const <String, String>{
                'User-Agent': 'JingwayChinese-Textbook/1.0',
                'Accept': '*/*',
              },
            ),
          );

  final Dio _dio;

  Future<Directory> textbooksDir() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/textbooks');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _safeFileName(TextbookItem item, {required String ext}) {
    final String base = item.id
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\u4e00-\u9fff]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final String clipped = base.length > 80 ? base.substring(0, 80) : base;
    return '$clipped.$ext';
  }

  Future<File?> localFileIfExists(
    TextbookItem item, {
    required String ext,
  }) async {
    final Directory dir = await textbooksDir();
    final File file = File('${dir.path}/${_safeFileName(item, ext: ext)}');
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  Future<Uint8List> fetchBytes(
    TextbookItem item, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final List<String> candidates = item.downloadCandidates;
    if (candidates.isEmpty) {
      throw StateError('没有可用下载地址');
    }
    Object? lastError;
    for (final String url in candidates) {
      try {
        final Response<List<int>> response = await _dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: onProgress == null
              ? null
              : (int count, int total) =>
                    onProgress(count, total < 0 ? null : total),
        );
        final List<int>? data = response.data;
        if (data != null && data.isNotEmpty) {
          // Git LFS pointer files start with this header — treat as failure.
          final String head = utf8.decode(
            data.take(40).toList(growable: false),
            allowMalformed: true,
          );
          if (head.startsWith('version https://git-lfs.github.com')) {
            throw StateError('Git LFS 指针，请换镜像或浏览器打开');
          }
          return Uint8List.fromList(data);
        }
      } catch (e) {
        lastError = e;
      }
    }
    throw StateError('下载失败：${lastError ?? 'empty'}');
  }

  Future<File> downloadToDocuments(
    TextbookItem item, {
    required String ext,
    void Function(int received, int? total)? onProgress,
  }) async {
    final File? existing = await localFileIfExists(item, ext: ext);
    if (existing != null) return existing;
    final Uint8List bytes = await fetchBytes(item, onProgress: onProgress);
    final Directory dir = await textbooksDir();
    final File file = File('${dir.path}/${_safeFileName(item, ext: ext)}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<String> fetchText(TextbookItem item) async {
    final File? cached = await localFileIfExists(item, ext: 'md');
    if (cached != null) {
      return cached.readAsString();
    }
    final Uint8List bytes = await fetchBytes(item);
    final String text = utf8.decode(bytes, allowMalformed: true);
    final Directory dir = await textbooksDir();
    final File file = File('${dir.path}/${_safeFileName(item, ext: 'md')}');
    await file.writeAsString(text, flush: true);
    return text;
  }
}
