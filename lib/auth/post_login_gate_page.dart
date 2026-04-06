import 'package:date_and_doing/views/home/dd_home.dart';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/views/onboarding/onboarding_profile_page.dart';
import './terms_acceptance_page.dart';

class PostLoginGatePage extends StatefulWidget {
  const PostLoginGatePage({super.key});

  @override
  State<PostLoginGatePage> createState() => _PostLoginGatePageState();
}

class _PostLoginGatePageState extends State<PostLoginGatePage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideNextStep();
    });
  }

  Future<void> _decideNextStep() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final terms = await _api.getTermsStatus();
      final acceptedTerms = terms["accepted_terms"] == true;

      if (!mounted) return;

      if (!acceptedTerms) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TermsAcceptancePage()),
        );
        return;
      }

      final onboarding = await _api.getOnboardingProfile();

      if (!mounted) return;

      if (onboarding.profileCompleted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const DdHome()));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OnboardingProfilePage(isOnboardingFlow: true),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 60),
              const SizedBox(height: 14),
              Text(
                "No pudimos continuar",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? "Ocurrió un problema al validar tu perfil.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _decideNextStep,
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
