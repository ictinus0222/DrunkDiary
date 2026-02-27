import 'dart:io';

void main() {
  final readmeFile = File('README.md');
  if (!readmeFile.existsSync()) {
    print('Error: README.md not found.');
    return;
  }

  String readmeContent = readmeFile.readAsStringSync();

  // Define sync tasks
  final tasks = [
    SyncTask(
      marker: 'OVERVIEW',
      sourceFile: 'Docs/PRD.md',
      header: '## 3. Goals & Objectives',
      processor: (content) => content
          .split('\n')
          .where((line) => line.startsWith('-'))
          .take(4)
          .join('\n'),
    ),
    SyncTask(
      marker: 'TECH',
      sourceFile: 'Docs/TECH_STACK.md',
      header: '## 9. Dependencies Lock', // This has a good summary or list
      processor: (content) {
        // Extract the yaml block and format it
        final lines = content.split('\n');
        final libraries = <String>[];
        bool inYaml = false;
        for (var line in lines) {
          if (line.contains('```yaml'))
            inYaml = true;
          else if (line.contains('```'))
            inYaml = false;
          else if (inYaml &&
              line.trim().isNotEmpty &&
              !line.contains('dependencies:')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final name = parts[0].trim().replaceAll('  ', '');
              if (name != 'sdk' && parts[1].trim().isNotEmpty) {
                libraries.add('- **$name:** ${parts[1].trim()}');
              }
            }
          }
        }
        return libraries.take(6).join('\n');
      },
    ),
    SyncTask(
      marker: 'FLOW',
      sourceFile: 'Docs/APP_FLOW.md',
      header: '## 3. Navigation Map (Actual Structure Only)',
      processor: (content) {
        if (content.contains('```text')) {
          final match =
              RegExp(r'```text\r?\n([\s\S]*?)```').firstMatch(content);
          if (match != null) return '```text\n${match.group(1)!.trim()}\n```';
        }
        return '```text\n${content.trim()}\n```';
      },
    ),
    SyncTask(
      marker: 'ARCH',
      sourceFile: 'Docs/BACKEND_STRUCTURE.md',
      header: '### Collection:', // Look for collection blocks directly
      processor: (content) {
        // We need to look across the whole file for collections
        final fileContent =
            File('Docs/BACKEND_STRUCTURE.md').readAsStringSync();
        final collections = RegExp(r'### Collection: `(\w+)`')
            .allMatches(fileContent)
            .map((m) => '- **`${m.group(1)}`**')
            .toList();
        return 'DrunkDiary uses a **Serverless (BaaS)** architecture based on Firebase:\n${collections.join('\n')}';
      },
    ),
    SyncTask(
      marker: 'DESIGN',
      sourceFile: 'Docs/FRONTEND_GUIDELINES.md',
      header: '## 1. Design Principles',
      processor: (content) =>
          content.replaceFirst('(Inferred From UI)', '').trim(),
    ),
  ];

  for (var task in tasks) {
    print('Syncing ${task.marker}...');
    final sourceContent = task.extractContent();
    if (sourceContent != null) {
      readmeContent = task.injectInto(readmeContent, sourceContent);
    }
  }

  readmeFile.writeAsStringSync(readmeContent);
  print('Successfully synchronized README.md with Docs/');
}

class SyncTask {
  final String marker;
  final String sourceFile;
  final String header;
  final String Function(String content) processor;

  SyncTask({
    required this.marker,
    required this.sourceFile,
    required this.header,
    required this.processor,
  });

  String? extractContent() {
    final file = File(sourceFile);
    if (!file.existsSync()) return null;

    final content = file.readAsStringSync();
    final headerIndex = content.indexOf(header);
    if (headerIndex == -1) return null;

    final startPos = headerIndex + header.length;
    // Find next header of same or higher level
    final nextHeaderRegex = RegExp(r'\n#{1,3} ');
    final nextMatch = nextHeaderRegex.firstMatch(content.substring(startPos));

    String sectionContent;
    if (nextMatch != null) {
      sectionContent =
          content.substring(startPos, startPos + nextMatch.start).trim();
    } else {
      sectionContent = content.substring(startPos).trim();
    }

    return processor(sectionContent);
  }

  String injectInto(String readme, String newContent) {
    final startMarker = '<!-- SYNC_${marker}_START -->';
    final endMarker = '<!-- SYNC_${marker}_END -->';

    final startIndex = readme.indexOf(startMarker);
    final endIndex = readme.indexOf(endMarker);

    if (startIndex == -1 || endIndex == -1) return readme;

    return readme.replaceRange(
      startIndex + startMarker.length,
      endIndex,
      '\n$newContent\n',
    );
  }
}
