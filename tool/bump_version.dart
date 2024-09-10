// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

List<String> getopt(String parseOptions, List<String> args) {
  final optString = ',$parseOptions,';
  var stopParsing = false;
  final List<String> options = [];
  final List<String> result = [];
  outer:
  while (args.isNotEmpty) {
    final nextArg = args.removeAt(0);
    if (nextArg == '--') {
      stopParsing = true;
      continue;
    }

    if (!stopParsing && nextArg.isNotEmpty) {
      switch (nextArg) {
        case '--d':
          continue outer;
        case '--t':
          continue outer;
        case '--h':
          continue outer;
      }
      if (optString.contains(RegExp('.*,$nextArg:,.*'))) {
        options.add(nextArg);
        if (args.isNotEmpty) {
          options.add(args.removeAt(0));
        }
        continue outer;
      } else if (optString.contains(RegExp('.*,$nextArg,.*'))) {
        options.add(nextArg);
        continue outer;
      }
    }
    result.add(nextArg);
  }
  if (parseOptions.isEmpty) {
    return result;
  } else {
    options.add('--');
    options.addAll(result);
    return options;
  }
}

final versionRegex = r'(?:(\d+)\.(\d+)\.(\d+)(?:\+(.+))?)';

class Version {
  final int _major;
  final int _minor;
  final int _patch;
  final String? _buildNumber;
  static final defaultVersion = Version(0, 0, 1);

  Version(this._major, this._minor, this._patch, [this._buildNumber]);

  static bool isValid(String? versionStr) {
    if (versionStr == null || versionStr.isEmpty) {
      return false;
    }
    RegExp pattern = RegExp(r'^(?:(\d+)\.(\d+)\.(\d+)(?:\+(.+))?)$');
    return pattern.hasMatch(versionStr);
  }

  static Version? fromString(String? versionStr, [String? buildNumber]) {
    RegExp pattern = RegExp(r'^(?:(\d+)\.(\d+)\.(\d+)(?:\+(.+))?)$');

    if (versionStr == null || !pattern.hasMatch(versionStr)) {
      return null;
    }

    final match = pattern.firstMatch(versionStr)!;
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    buildNumber ??= match.group(4);

    return Version(major, minor, patch, buildNumber);
  }

  static Version? fromFile(String filePath, [String? prefix, String? suffix]) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File not found: $filePath');
      return null;
    }

    RegExp pattern = RegExp('${prefix ?? ''}($versionRegex)${suffix ?? ''}');

    for (final line in file.readAsLinesSync()) {
      final match = pattern.firstMatch(line);
      if (match == null) {
        continue;
      }
      return fromString(match.group(1)!);
    }
    return null;
  }

  @override
  String toString() {
    if (_buildNumber == null) {
      return '$_major.$_minor.$_patch';
    } else {
      return '$_major.$_minor.$_patch+$_buildNumber';
    }
  }

  Version bumpPatch([String? buildNumber]) =>
      Version(_major, _minor, _patch + 1, buildNumber ?? _buildNumber);

  Version bumpMinor([String? buildNumber]) =>
      Version(_major, _minor + 1, 0, buildNumber ?? _buildNumber);

  Version bumpMajor([String? buildNumber]) =>
      Version(_major + 1, 0, 0, buildNumber ?? _buildNumber);
}

void prependToFile(String path, String prefix) {
  final file = File(path);
  try {
    final contents = file.readAsStringSync();
    file.writeAsStringSync(prefix + contents);
  } catch (e) {
    print('Failed to update $path: $e');
  }
}

void replaceInFile(String path, String from, String to, [String? prefix]) {
  final file = File(path);
  final contents = file.readAsStringSync();
  if (prefix != null) {
    from = prefix + from;
    to = prefix + to;
  }
  file.writeAsStringSync(contents.replaceAll(from, to));
}

List<String> getChangelogs() {
  final changelogs = <String>[];
  print('Enter changelogs (empty line to stop):');
  while (true) {
    final line = stdin.readLineSync();
    if (line == null || line.isEmpty) {
      break;
    }
    changelogs.add(line);
  }
  return changelogs;
}

String changelogToString(Version version, List<String> changelogs,
    {bool versionInBraces = true, String tab = '*'}) {
  String log = versionInBraces ? '## [$version]\n' : '## $version\n';
  for (final changelog in changelogs) {
    log += '$tab $changelog\n';
  }
  log += '\n';
  return log;
}

enum BumpType { major, minor, patch }

void main(List<String> args) {
  final opts = getopt('-p,-M,-m,-h', args.toList());
  BumpType? bumpType;

  while (opts.isNotEmpty) {
    String opt = opts.removeAt(0);
    if (opt == '--') {
      break;
    }
    switch (opt) {
      case '-M':
        bumpType = BumpType.major;
        break;
      case '-m':
        bumpType = BumpType.minor;
        break;
      case '-p':
        bumpType = BumpType.patch;
        break;
      case '-h':
        print('usage: bump_version.dart [-M|-m|-p|-h]');
        exit(0);
    }
  }

  final rootDir = Directory.current;

  final pubspecFile = '${rootDir.path}/pubspec.yaml';
  if (!File(pubspecFile).existsSync()) {
    print('Run from root folder');
    exit(1);
  }

  // Get current version
  Version? currentVersion = Version.fromFile(pubspecFile, 'version: ');
  if (currentVersion == null) {
    print('Failed to parse version from $pubspecFile');
    exit(2);
  }

  // Get next version
  Version? nextVersion;
  if (bumpType == BumpType.major) {
    nextVersion = currentVersion.bumpMajor();
  } else if (bumpType == BumpType.minor) {
    nextVersion = currentVersion.bumpMinor();
  } else if (bumpType == BumpType.patch) {
    nextVersion = currentVersion.bumpPatch();
  } else {
    stdout.write('Enter new version (current version is $currentVersion): ');
    final versionStr = stdin.readLineSync(encoding: utf8);
    nextVersion = Version.fromString(versionStr);
    if (nextVersion == null) {
      print('Invalid version: $versionStr');
      exit(3);
    }
  }

  // Get changelogs
  final changelogs = getChangelogs();
  if (changelogs.isEmpty) {
    print('No changelog provided');
    return;
  }

  // Update changelogs in files
  final log = changelogToString(nextVersion, changelogs);
  prependToFile('CHANGELOG.md', log);

  // Update version in files
  replaceInFile(pubspecFile, currentVersion.toString(), nextVersion.toString(),
      '\nversion: ');

  print("Updated version from '$currentVersion' to $nextVersion");
  print("Commit log: ${changelogs.join('. ')}");
}
