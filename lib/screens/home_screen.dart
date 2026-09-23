import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/resume_service.dart';
import 'profile_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openResumeBuilder(BuildContext context) async {
    final userId = context.read<AuthService>().currentUser?.uid;
    String? existingResumeId;

    if (userId != null) {
      try {
        final resumes =
            await context.read<ResumeService>().watchResumes(userId).first;
        if (resumes.isNotEmpty) existingResumeId = resumes.first.resumeId;
      } catch (_) {
        // Fall back to starting a new resume if the lookup fails (e.g. offline).
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(resumeId: existingResumeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final email = auth.currentUser?.email ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Center(child: Text('Welcome, $email!')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openResumeBuilder(context),
        icon: const Icon(Icons.add),
        label: const Text('Build Resume'),
      ),
    );
  }
}
