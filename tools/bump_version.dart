// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const changeLogFiles = ['CHANGELOG.md'];
const filesToUpdate = [
  'pubspec.yaml',
];

class Version {
  final int _major;
  final int _minor;
  final int _patch;

  Version(this._major, this._minor, this._patch);

  @override
  String toString() {
    return '$_major.$_minor.$_patch';
  }

  static Version fromString(String versionStr) {
    final List<int> versions =
        versionStr.split('.').map((str) => int.parse(str)).toList();
    return Version(versions[0], versions[1], versions[2]);
  }
}

void updateVersion(Version from, Version to) {
  for (final path in filesToUpdate) {
    final file = File(path);
    final contents = file.readAsStringSync();
    file.writeAsStringSync(contents.replaceAll(from.toString(), to.toString()));
  }
}

void changeLog(Version to, String log) {
  for (final path in changeLogFiles) {
    final file = File(path);
    final contents = file.readAsStringSync();
    final prefix = '## [$to]\n\n- $log\n\n';
    file.writeAsStringSync(prefix);
    file.writeAsStringSync(contents, mode: FileMode.append);
  }
}

Version? getVersion(File file, RegExp pattern) {
  for (final line in file.readAsLinesSync()) {
    final match = pattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    return Version.fromString(match.group(1)!);
  }
  return null;
}

void main(List<String> args) {
  final rootDir = Directory.current;

  final bumpType = ['major', 'minor', 'patch'];

  if (args.isEmpty || !bumpType.contains(args[0])) {
    print('Specify major, minor, or patch');
    return;
  }

  final pubspecFile = File('${rootDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Run from root folder');
    return;
  }

  Version? currentVersion = getVersion(pubspecFile, RegExp(r'^version: (.*)$'));

  if (currentVersion == null) {
    return;
  }

  stdout.write('Enter changelog: ');
  final log = stdin.readLineSync(encoding: utf8);
  if (log == null) {
    return;
  }

  late Version nextVersion;

  if (args[0] == 'major') {
    nextVersion = Version(currentVersion._major + 1, 0, 0);
  } else if (args[0] == 'minor') {
    nextVersion = Version(currentVersion._major, currentVersion._minor + 1, 0);
  } else if (args[0] == 'patch') {
    nextVersion = Version(currentVersion._major, currentVersion._minor,
        currentVersion._patch + 1);
  }

  updateVersion(currentVersion, nextVersion);
  changeLog(nextVersion, log);

  print(
      "Updated version from '$currentVersion' to $nextVersion with log: $log");
}
