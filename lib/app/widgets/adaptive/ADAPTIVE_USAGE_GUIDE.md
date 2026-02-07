# Adaptive Widgets Usage Guide

This guide covers the adaptive widget system that provides platform-specific UI components for Pendeza app. These widgets automatically render Material Design on Android and Cupertino (iOS-style) on iOS.

## Table of Contents

1. [Setup](#setup)
2. [Core Concepts](#core-concepts)
3. [Widgets Reference](#widgets-reference)
4. [Migration Guide](#migration-guide)
5. [Best Practices](#best-practices)

---

## Setup

The adaptive system is built on `flutter_platform_widgets` and uses our custom theme configuration.

### Required Imports

```dart
// Core adaptive imports
import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/adaptive_theme.dart';

// Adaptive widgets
import 'package:pendeza/app/widgets/adaptive/adaptive_scaffold.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_app_bar.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_button.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_dialog.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_bottom_nav.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_text_field.dart';
```

---

## Core Concepts

### Platform Detection

Use `PlatformConfig` for platform checks:

```dart
if (PlatformConfig.isIOS) {
  // iOS-specific logic
}

if (PlatformConfig.useCupertino) {
  // Use Cupertino widgets (iOS + macOS)
}

// Select value based on platform
final icon = PlatformConfig.platformSelect(
  material: Icons.arrow_back,
  cupertino: CupertinoIcons.back,
);
```

### Adaptive Theming

Use `AdaptiveTheme` for brightness-aware and platform-aware styling:

```dart
// Get colors based on current brightness (light/dark)
final bgColor = AdaptiveTheme.backgroundColor(context);
final textColor = AdaptiveTheme.textPrimaryColor(context);

// Get platform-specific values
final padding = AdaptiveTheme.adaptiveCardPadding;
final radius = AdaptiveTheme.adaptiveButtonRadius;

// Select based on both platform AND brightness
final value = AdaptiveTheme.adaptive(
  context,
  materialLight: 16.0,
  materialDark: 14.0,
  cupertinoLight: 12.0,
  cupertinoDark: 10.0,
);
```

---

## Widgets Reference

### AdaptiveScaffold

Platform-aware scaffold with automatic app bar styling.

```dart
AdaptiveScaffold(
  title: 'Screen Title',
  leading: AdaptiveBackButton(),
  trailing: AdaptiveIconButton(
    icon: Icons.settings,
    onPressed: () {},
  ),
  body: YourContent(),
  floatingActionButton: AdaptiveFloatingActionButton(
    icon: Icons.add,
    onPressed: () {},
  ),
  bottomNavigationBar: yourBottomNav,
)
```

### AdaptiveAppBar

Standalone app bar for more control.

```dart
AdaptiveAppBar(
  title: 'Title',
  leading: AdaptiveBackButton(),
  actions: [
    AdaptiveIconButton(icon: Icons.share, onPressed: () {}),
    AdaptiveIconButton(icon: Icons.more_vert, onPressed: () {}),
  ],
  centerTitle: true,
  elevation: 0,
)
```

#### Sliver App Bar

For use in `CustomScrollView`:

```dart
CustomScrollView(
  slivers: [
    AdaptiveSliverAppBar(
      title: 'Large Title',
      largeTitle: true,  // iOS large title style
      pinned: true,
      expandedHeight: 120,
    ),
    SliverList(...),
  ],
)
```

### AdaptiveButton Variants

#### Primary Button (Elevated/Filled)

```dart
AdaptiveButton(
  onPressed: () {},
  child: Text('Submit'),
  isLoading: _isLoading,
  isExpanded: true,  // Full width
)
```

#### Text Button

```dart
AdaptiveTextButton(
  onPressed: () {},
  child: Text('Cancel'),
)
```

#### Outlined Button

```dart
AdaptiveOutlinedButton(
  onPressed: () {},
  child: Text('Secondary Action'),
  borderColor: AppColors.primary,
)
```

#### Gradient Button

```dart
AdaptiveGradientButton(
  onPressed: () {},
  child: Text('Premium Action'),
  gradient: AppColors.primaryGradient,
  isExpanded: true,
)
```

#### Icon Button

```dart
AdaptiveIconButton(
  icon: Icons.favorite,
  onPressed: () {},
  color: AppColors.error,
  tooltip: 'Add to favorites',
)
```

#### Floating Action Button

```dart
AdaptiveFloatingActionButton(
  icon: Icons.add,
  onPressed: () {},
  extended: true,
  label: 'New Booking',
)
```

### AdaptiveTextField Variants

#### Standard Text Field

```dart
AdaptiveTextField(
  controller: _controller,
  labelText: 'Email',
  hintText: 'Enter your email',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  onChanged: (value) => print(value),
)
```

#### Password Field

```dart
AdaptivePasswordField(
  controller: _passwordController,
  labelText: 'Password',
  hintText: 'Enter password',
  validator: (value) => (value?.length ?? 0) < 8 ? 'Too short' : null,
)
```

#### Search Field

```dart
AdaptiveSearchField(
  controller: _searchController,
  hintText: 'Search salons...',
  onChanged: (query) => _filterResults(query),
  onClear: () => _clearSearch(),
)
```

#### Text Area (Multiline)

```dart
AdaptiveTextArea(
  controller: _notesController,
  labelText: 'Notes',
  hintText: 'Add any special requests...',
  maxLines: 5,
  maxLength: 500,
)
```

### AdaptiveDialog Functions

#### Alert Dialog

```dart
await showAdaptiveDialog(
  context: context,
  title: 'Confirm Action',
  content: 'Are you sure you want to proceed?',
  confirmText: 'Yes',
  cancelText: 'No',
  onConfirm: () => Navigator.pop(context, true),
);
```

#### Confirmation Dialog

```dart
final confirmed = await showAdaptiveConfirmDialog(
  context: context,
  title: 'Log Out',
  content: 'Are you sure you want to log out?',
  confirmText: 'Log Out',
  cancelText: 'Cancel',
);

if (confirmed) {
  // Perform logout
}
```

#### Delete Confirmation

```dart
final shouldDelete = await showAdaptiveDeleteDialog(
  context: context,
  title: 'Delete Appointment',
  content: 'This action cannot be undone.',
);
```

#### Action Sheet

```dart
final result = await showAdaptiveActionSheet<String>(
  context: context,
  title: 'Choose Option',
  message: 'Select an action to perform',
  actions: [
    AdaptiveSheetAction(
      label: 'Edit',
      value: 'edit',
      icon: Icons.edit,
    ),
    AdaptiveSheetAction(
      label: 'Share',
      value: 'share',
      icon: Icons.share,
    ),
    AdaptiveSheetAction(
      label: 'Delete',
      value: 'delete',
      icon: Icons.delete,
      isDestructive: true,
    ),
  ],
);
```

#### Loading Dialog

```dart
// Show loading
showAdaptiveLoadingDialog(
  context: context,
  message: 'Please wait...',
);

// Dismiss when done
Navigator.of(context).pop();
```

#### Snackbar / Toast

```dart
showAdaptiveSnackBar(
  context: context,
  message: 'Booking confirmed!',
  isSuccess: true,
);

showAdaptiveSnackBar(
  context: context,
  message: 'Something went wrong',
  isError: true,
);
```

### AdaptiveBottomNav

#### Standard Navigation

```dart
AdaptiveBottomNav(
  items: [
    AdaptiveNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    AdaptiveNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
    ),
    AdaptiveNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Bookings',
      badge: 3,  // Shows notification badge
    ),
    AdaptiveNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ],
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
)
```

#### Custom Animated Navigation

```dart
AdaptiveBottomNavBar(
  items: navItems,
  currentIndex: _selectedIndex,
  onTap: _onTabSelected,
  height: 65,
  iconSize: 26,
  showLabels: true,
  animationDuration: Duration(milliseconds: 250),
)
```

#### Floating Navigation

```dart
AdaptiveFloatingBottomNav(
  items: navItems,
  currentIndex: _selectedIndex,
  onTap: _onTabSelected,
  showLabels: true,  // Expands selected item
  borderRadius: 30,
  elevation: 10,
)
```

---

## Migration Guide

### Migrating from MaterialApp

**Before:**
```dart
MaterialApp.router(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  routerConfig: AppRouter.router,
)
```

**After:**
```dart
PlatformProvider(
  settings: PlatformSettingsData(
    iosUsesMaterialWidgets: true,
  ),
  builder: (context) => PlatformTheme(
    materialLightTheme: AppTheme.lightTheme,
    materialDarkTheme: AppTheme.darkTheme,
    cupertinoLightTheme: AppTheme.cupertinoLightTheme,
    cupertinoDarkTheme: AppTheme.cupertinoDarkTheme,
    builder: (context) => PlatformApp.router(
      routerConfig: AppRouter.router,
    ),
  ),
)
```

### Migrating Scaffold

**Before:**
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Title'),
    leading: IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  ),
  body: content,
)
```

**After:**
```dart
AdaptiveScaffold(
  title: 'Title',
  leading: AdaptiveBackButton(),
  body: content,
)
```

### Migrating Buttons

**Before:**
```dart
ElevatedButton(
  onPressed: _submit,
  child: Text('Submit'),
)
```

**After:**
```dart
AdaptiveButton(
  onPressed: _submit,
  child: Text('Submit'),
)
```

### Migrating TextFields

**Before:**
```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email),
  ),
)
```

**After:**
```dart
AdaptiveTextField(
  controller: _controller,
  labelText: 'Email',
  prefixIcon: Icons.email,
)
```

### Migrating Dialogs

**Before:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes')),
    ],
  ),
);
```

**After:**
```dart
final result = await showAdaptiveConfirmDialog(
  context: context,
  title: 'Confirm',
  content: 'Are you sure?',
);
```

---

## Best Practices

### 1. Always Use Adaptive Colors

```dart
// Good
final color = AdaptiveTheme.primaryColor(context);

// Avoid (doesn't respect dark mode)
final color = AppColors.primary;
```

### 2. Use Platform-Specific Icons

```dart
final icon = PlatformConfig.platformSelect(
  material: Icons.arrow_back,
  cupertino: CupertinoIcons.back,
);
```

### 3. Prefer Adaptive Widgets for User-Facing UI

Use adaptive widgets for:
- Navigation (app bars, bottom nav)
- Buttons and interactive elements
- Form inputs
- Dialogs and alerts

Material-only widgets are fine for:
- Internal/admin screens
- Complex custom layouts
- Widgets without Cupertino equivalents

### 4. Test on Both Platforms

Always test your UI on both iOS and Android simulators/devices to ensure proper rendering.

### 5. Handle Loading States

```dart
AdaptiveButton(
  onPressed: _isLoading ? null : _submit,
  isLoading: _isLoading,
  child: Text('Submit'),
)
```

### 6. Use Consistent Spacing

```dart
Padding(
  padding: AdaptiveTheme.adaptivePagePadding,
  child: content,
)
```

---

## File Structure

```
lib/app/widgets/adaptive/
├── adaptive_app_bar.dart       # App bars and navigation buttons
├── adaptive_bottom_nav.dart    # Bottom navigation variants
├── adaptive_button.dart        # Button variants
├── adaptive_dialog.dart        # Dialogs, sheets, snackbars
├── adaptive_scaffold.dart      # Scaffold wrapper
├── adaptive_text_field.dart    # Text input variants
└── ADAPTIVE_USAGE_GUIDE.md     # This guide
```

## Related Files

```
lib/app/config/
├── platform_config.dart        # Platform detection utilities
└── theme/
    ├── adaptive_theme.dart     # Adaptive theming utilities
    ├── app_colors.dart         # Color constants
    └── app_theme.dart          # Material & Cupertino themes
```
