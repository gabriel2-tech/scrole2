import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../app/theme/text_styles.dart';

class CommunityReceivedInvitationsScreen extends StatelessWidget {
  const CommunityReceivedInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitations reçues', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Text('Vous n\'avez aucune invitation en attente.', style: AppTextStyles.body),
      ),
    );
  }
}
