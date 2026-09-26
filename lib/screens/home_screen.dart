import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/resume_list.dart';
import 'profile_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openForm(BuildContext context, {String? resumeId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileFormScreen(resumeId: resumeId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    // AuthGate only shows this screen to a signed-in user.
    final userId = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: ResumeList(
        userId: userId,
        onOpen: (id) => _openForm(context, resumeId: id),
        onCreate: () => _openForm(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New resume'),
      ),
    );
  }
}
