import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Use a Provider to access the Supabase client easily
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class SupabaseInit {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:
          'https://zcnosawcjcshmbmnrakk.supabase.co', // TODO: Replace with env variable
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpjbm9zYXdjamNzaG1ibW5yYWtrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MTIyOTQsImV4cCI6MjA4NDA4ODI5NH0.wevYvAO96KIGbvAZFw_HiwkwbUdzsTQ8pets4nw2X9k', // TODO: Replace with env variable
    );
  }
}
