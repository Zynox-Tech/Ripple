import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = {
    'en': {
      'app_name': 'Ripple',
      'splash_subtitle': 'School Swaps Made Simple',
      'splash_desc1': 'Find matching families in your area who want to swap schools.',
      'splash_desc2': 'Communicate securely without sharing your phone number.',
      'splash_desc3': 'Follow a step-by-step checklist to coordinate the official transfer.',
      'continue_google': 'Continue with Google',
      'skip': 'Skip',
      'welcome_back': 'Welcome Back',
      'parent_setup': 'Parent Profile Setup',
      'parent_name': 'Parent Name',
      'city': 'City',
      'area': 'London Borough / Area',
      'select_city': 'Select City',
      'select_area': 'Select Area',
      'children_setup': 'Children Profiles',
      'add_child': '+ Add Another Child',
      'child_name': 'Child\'s First Name',
      'grade': 'Year / Grade',
      'current_school': 'Current School',
      'target_school': 'Target School(s)',
      'save_continue': 'Save & Continue',
      'home': 'Home',
      'matches': 'Matches',
      'chats': 'Chats',
      'insights': 'Insights',
      'profile': 'Profile',
      'new_matches': 'New Matches',
      'active_chats': 'Active Chats',
      'matches_week': 'Matches This Week',
      'unread_nudge': 'You have {count} unread messages',
      'no_unread': 'No unread messages',
      'tip_title': 'Admissions Tip',
      'tip_body': 'Applying at the start of a term increases chances of approval by 40%.',
      'recent_chat': 'Recent Active Chat',
      'compatibility': 'Compatibility',
      'distance': '{dist} km',
      'filter_label': 'Filter by Area / Year',
      'sort_label': 'Sort by Compatibility',
      'locked_title': 'Upgrade to Premium',
      'locked_desc': 'Unlock full match details, maps, and direct chat rooms!',
      'school_swap_path': 'School Swap Path',
      'compatibility_breakdown': 'Compatibility Breakdown',
      'distance_fit': 'Distance Fit',
      'grade_match': 'Year Match',
      'timing_readiness': 'Timing Readiness',
      'profile_completeness': 'Profile Completeness',
      'disclaimer': 'Disclaimer: Ripple is a coordination tool. Official transfers must be processed directly via schools or local councils.',
      'connect_request': 'Send Connection Request',
      'chat_room': 'Chat Room',
      'checklist_title': 'Coordination Checklist',
      'check_applied': 'Submitted Transfer Form',
      'check_received': 'Received School Reply',
      'check_confirmed': 'Transfer Confirmed',
      'check_date': 'Move Date Agreed',
      'mark_complete': 'Mark Move Complete',
      'chat_connected': 'You are now connected! Start coordinating.',
      'quick_applied': 'I have applied',
      'quick_waiting': 'Waiting for response',
      'quick_meet': 'Let\'s talk details',
      'insights_hub': 'Insights Hub',
      'transfer_rate': 'Open Transfer Seats',
      'best_timing': 'Best Application Timing',
      'waiting_position': 'Estimated Waitlist Rank',
      'school_profile': 'School Profile',
      'admissions_catchment': 'Catchment Area Admits',
      'admission_tips': 'Admission Hints',
      'children': 'Children',
      'notification_settings': 'Push Notifications',
      'sign_out': 'Sign Out',
      'success_wall': 'Success Wall',
      'success_wall_subtitle': 'Real UK families who successfully swapped!',
      'premium_badge': 'Verified Badge',
      'plans': 'Subscription Tiers',
      'upgrade_now': 'Upgrade Plan',
      'pkr_month': '£{price}/mo',
      'pkr_year': '£{price}/yr',
      'save_20': 'Save 20%',
      'pay_jazzcash': 'PayPal',
      'pay_easypaisa': 'Apple Pay',
      'pay_card': 'Debit/Credit Card',
      'verified_badge_title': 'Verified Account',
      'verified_badge_desc': 'Upload school fee receipt/ID to boost ranking by 25%.',
      'upload_receipt': 'Upload Proof Document',
      
      // Standard auth translations
      'login': 'Log In',
      'sign_up': 'Sign Up',
      'email': 'Email Address',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'name_hint': 'Enter your full name',
      'email_hint': 'name@example.com',
      'password_hint': 'Enter password (min. 6 characters)',
      'confirm_password_hint': 'Re-enter your password',
      'invalid_email': 'Please enter a valid email address',
      'invalid_password': 'Password must be at least 6 characters long',
      'password_mismatch': 'Passwords do not match',
      'or_divider': 'OR',
      'have_account': 'Already have an account? Log In',
      'need_account': 'Don\'t have an account? Sign Up',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'theme_mode': 'Theme Mode',
    },
  };

  String translate(String key, {Map<String, String>? arguments}) {
    String value = _localizedValues['en']?[key] ?? key;
    if (arguments != null) {
      arguments.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }

  bool get isUrdu => false;
  TextDirection get textDirection => TextDirection.ltr;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
