import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/models.dart';

const pine = Color(0xFF304E42);
const cream = Color(0xFFF8F6F1);
const muted = Color(0xFF808278);
const clay = Color(0xFFA66F51);
const photos = [
  'assets/images/japan.jpg',
  'assets/images/business.jpg',
  'assets/images/calm.jpg',
];
const areas = [
  'Travel',
  'Career / Business',
  'Money',
  'Relationships',
  'Home',
  'Health / Wellness',
  'Experiences',
  'Personal Growth',
  'How I Want Life to Feel',
  'Something Else',
];
String rhythmName(Rhythm r) => switch (r) {
  Rhythm.daily => 'Daily',
  Rhythm.weekly => 'Weekly',
  Rhythm.occasional => 'Occasionally',
};
String toneName(Tone t) => switch (t) {
  Tone.grounded => 'Grounded',
  Tone.motivational => 'Motivational',
  Tone.manifestation => 'Manifestation',
  Tone.none => 'No Quotes',
};
String shortDate(DateTime d) =>
    '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.day}, ${d.year}';
String monthDate(DateTime d) =>
    '${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1]} ${d.year}';
TextStyle editorial(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w500,
}) => TextStyle(
  fontFamily: 'Cormorant',
  fontSize: size,
  height: 1.04,
  fontWeight: weight,
  color: color,
  letterSpacing: -.8,
);

ThemeData stillTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: pine,
    brightness: brightness,
    surface: dark ? const Color(0xFF1C2420) : cream,
    primary: dark ? const Color(0xFFBCCFBE) : pine,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Manrope',
    textTheme: ThemeData(brightness: brightness).textTheme
        .apply(fontFamily: 'Manrope'),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    dividerTheme: DividerThemeData(
      color: dark ? Colors.white12 : const Color(0xFFE5E5DC),
      space: 32,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF45594B) : pine,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Manrope',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? const Color(0xFFBCCFBE) : pine,
        foregroundColor: dark ? pine : Colors.white,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        side: BorderSide(color: scheme.outline.withValues(alpha: .25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? Colors.white.withValues(alpha: .04)
          : Colors.white.withValues(alpha: .7),
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: .09),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

class Photo extends StatelessWidget {
  const Photo(
    this.path, {
    super.key,
    this.height,
    this.width,
    this.radius = 20,
  });
  final String path;
  final double? height, width;
  final double radius;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object error, StackTrace? stack) =>
        Container(
          color: const Color(0xFFD9DFD2),
          child: const Center(
            child: Icon(Icons.landscape_outlined, color: pine, size: 40),
          ),
        );
    final Widget image;
    if (path.startsWith('data:')) {
      image = Image.memory(
        base64Decode(path.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: fallback,
        width: width ?? double.infinity,
        height: height,
        gaplessPlayback: true,
      );
    } else {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: fallback,
        width: width ?? double.infinity,
        height: height,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(height: height, width: width, child: image),
    );
  }
}

Future<String?> choosePhoto() async {
  final photo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1400,
    imageQuality: 78,
  );
  if (photo == null) return null;
  final bytes = await photo.readAsBytes();
  if (bytes.length > 2500000) {
    throw StateError('Choose a smaller photo, under 2.5 MB.');
  }
  // Copy the bytes into durable storage. Never retain a temporary picker path.
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: color ?? muted,
    ),
  );
}

class Paper extends StatelessWidget {
  const Paper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: .035)
          : const Color(0xFFF0F0E8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class EmptyMoment extends StatelessWidget {
  const EmptyMoment({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.icon = Icons.spa_outlined,
  });
  final String title, body;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 38, color: muted),
        const SizedBox(height: 22),
        Text(title, textAlign: TextAlign.center, style: editorial(32)),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.7, fontSize: 13),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
}

Future<T?> sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: child,
        ),
      ),
    );
