import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../app/theme/text_styles.dart';

class MyCommunityPostsScreen extends StatelessWidget {
  const MyCommunityPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes publications', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Vous n\'avez publié aucun contenu pour le moment.', style: AppTextStyles.body),
      ),
    );
  }
}
