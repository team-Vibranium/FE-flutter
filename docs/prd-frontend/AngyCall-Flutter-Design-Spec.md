# AngyCall Flutter Design Specification

## Overview
AngyCall 모바일 앱을 위한 Flutter 디자인 시스템 및 컴포넌트 가이드입니다. Material Design 3를 기반으로 하며, 일관성 있는 사용자 경험을 제공합니다.

## Design System Foundation

### Color Palette

#### Material Color System
```dart
// Primary Colors
static const MaterialColor primarySwatch = MaterialColor(
  0xFFE53E3E, // Red-500
  <int, Color>{
    50: Color(0xFFFEE5E5),
    100: Color(0xFFFCCCCC),
    200: Color(0xFFF99999),
    300: Color(0xFFF66666),
    400: Color(0xFFF23333),
    500: Color(0xFFE53E3E), // Primary
    600: Color(0xFFCC3535),
    700: Color(0xFFB22C2C),
    800: Color(0xFF992323),
    900: Color(0xFF801A1A),
  },
);

// Semantic Colors
static const Color primaryColor = Color(0xFFE53E3E);      // Red
static const Color secondaryColor = Color(0xFF48BB78);     // Green  
static const Color tertiaryColor = Color(0xFF3182CE);      // Blue
static const Color warningColor = Color(0xFFED8936);       // Orange
static const Color errorColor = Color(0xFFE53E3E);         // Red
static const Color successColor = Color(0xFF48BB78);       // Green
static const Color infoColor = Color(0xFF3182CE);          // Blue

// Neutral Colors
static const Color surfaceColor = Color(0xFFFFFBFE);       // Background
static const Color onSurfaceColor = Color(0xFF1C1B1F);     // Text
static const Color surfaceVariantColor = Color(0xFFE7E0EC); // Cards
static const Color onSurfaceVariantColor = Color(0xFF49454F); // Secondary text
static const Color outlineColor = Color(0xFF79747E);        // Borders
static const Color outlineVariantColor = Color(0xFFCAC4D0); // Dividers
```

#### Dark Theme Colors
```dart
static const Color darkSurfaceColor = Color(0xFF1C1B1F);
static const Color darkOnSurfaceColor = Color(0xFFE6E1E5);
static const Color darkSurfaceVariantColor = Color(0xFF49454F);
static const Color darkOnSurfaceVariantColor = Color(0xFFCAC4D0);
static const Color darkOutlineColor = Color(0xFF938F99);
static const Color darkOutlineVariantColor = Color(0xFF49454F);
```

### Typography Scale

#### Text Styles
```dart
// Display Styles
static const TextStyle displayLarge = TextStyle(
  fontSize: 57,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.25,
  height: 1.12,
);

static const TextStyle displayMedium = TextStyle(
  fontSize: 45,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.16,
);

static const TextStyle displaySmall = TextStyle(
  fontSize: 36,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.22,
);

// Headline Styles
static const TextStyle headlineLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.25,
);

static const TextStyle headlineMedium = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.29,
);

static const TextStyle headlineSmall = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.33,
);

// Body Styles
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.5,
  height: 1.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.25,
  height: 1.43,
);

static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.4,
  height: 1.33,
);

// Label Styles
static const TextStyle labelLarge = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.1,
  height: 1.43,
);

static const TextStyle labelMedium = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  height: 1.33,
);

static const TextStyle labelSmall = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  height: 1.45,
);
```

### Spacing System
```dart
class AppSpacing {
  static const double xs = 4.0;    // 4dp
  static const double sm = 8.0;    // 8dp
  static const double md = 16.0;   // 16dp
  static const double lg = 24.0;   // 24dp
  static const double xl = 32.0;   // 32dp
  static const double xxl = 48.0;  // 48dp
  static const double xxxl = 64.0; // 64dp
}
```

### Border Radius
```dart
class AppRadius {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999.0));
}
```

### Elevation System
```dart
class AppElevation {
  static const double level0 = 0.0;   // Surface
  static const double level1 = 1.0;   // Cards at rest
  static const double level2 = 3.0;   // Cards on hover
  static const double level3 = 6.0;   // Dialogs, Navigation drawer
  static const double level4 = 8.0;   // Navigation bar
  static const double level5 = 12.0;  // FAB, Snackbar
}
```

## Component Library

### Button Components

#### Primary Button
```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
        ),
        elevation: AppElevation.level1,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(text, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
    );
  }
}
```

#### Secondary Button
```dart
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(text, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
```

#### Icon Button
```dart
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: color ?? Theme.of(context).colorScheme.onSurface,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sm,
        ),
      ),
    );
  }
}
```

### Input Components

#### Text Field
```dart
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
```

### Card Components

#### Basic Card
```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Theme.of(context).colorScheme.surface,
      elevation: AppElevation.level1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
```

#### Feature Card
```dart
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

### Call Interface Components

#### Call Button
```dart
class CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const CallButton({
    Key? key,
    required this.icon,
    this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 72.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Icon(
            icon,
            size: size * 0.4,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
```

#### Call Screen
```dart
class CallScreen extends StatelessWidget {
  final String contactName;
  final String? contactImage;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onMute;

  const CallScreen({
    Key? key,
    required this.contactName,
    this.contactImage,
    this.isIncoming = false,
    this.onAccept,
    this.onDecline,
    this.onMute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Contact info
            Column(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: contactImage != null 
                    ? NetworkImage(contactImage!) 
                    : null,
                  child: contactImage == null 
                    ? Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  contactName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isIncoming ? 'Incoming call' : 'Calling...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Call controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isIncoming)
                    CallButton(
                      icon: Icons.call,
                      backgroundColor: Colors.green,
                      iconColor: Colors.white,
                      onPressed: onAccept,
                    ),
                  CallButton(
                    icon: Icons.mic_off,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                    onPressed: onMute,
                    size: 56,
                  ),
                  CallButton(
                    icon: Icons.call_end,
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    onPressed: onDecline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Tag/Chip Components

#### Status Chip
```dart
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({
    Key? key,
    required this.label,
    required this.color,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Theme Configuration

### Light Theme
```dart
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  ),
  textTheme: const TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
      ),
    ),
  ),
  cardTheme: CardTheme(
    elevation: AppElevation.level1,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.md,
    ),
  ),
);
```

### Dark Theme
```dart
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  ),
  // ... same text theme and component themes
);
```

## Layout Guidelines

### Grid System
- **Phone**: 4dp base grid
- **Keylines**: 16dp margins on phone, 24dp on tablet
- **Content**: 8dp minimum touch target spacing
- **Cards**: 16dp padding, 8dp between cards

### Responsive Breakpoints
```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
}
```

### Safe Areas
- 모든 스크린에서 SafeArea 위젯 사용
- 상태 표시줄과 네비게이션 바 고려
- 노치와 둥근 모서리 대응

## Accessibility Guidelines

### Contrast Ratios
- **Normal text**: 최소 4.5:1
- **Large text**: 최소 3:1
- **UI elements**: 최소 3:1

### Touch Targets
- **최소 크기**: 48dp × 48dp
- **권장 크기**: 56dp × 56dp
- **간격**: 최소 8dp

### Semantic Labels
```dart
Semantics(
  label: 'Call contact',
  hint: 'Double tap to start a call',
  child: CallButton(...),
)
```

## Animation Guidelines

### Duration Standards
```dart
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
```

### Curve Standards
```dart
class AppCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve standard = Curves.easeInOutCubic;
}
```

## Usage Examples

### Basic Screen Layout
```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AngyCall'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppTextField(
              label: 'Phone Number',
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'Call',
              icon: Icons.call,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

이 디자인 명세서는 Flutter 개발 환경에서 AngyCall 앱을 개발할 때 일관성 있는 UI/UX를 구현하는 데 도움이 됩니다.