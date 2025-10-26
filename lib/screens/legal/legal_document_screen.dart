import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String mdFile;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.mdFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder(
        future: rootBundle.loadString('assets/legal/$mdFile'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
