import 'dart:convert';
import 'dart:io';

/// Loads `test/fixtures/<path>` as decoded JSON.
Map<String, dynamic> fixture(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync())
        as Map<String, dynamic>;
