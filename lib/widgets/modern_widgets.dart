import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

// Modern Card with Glass Effect
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useGlassEffect;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.useGlassEffect = false,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (useGlassEffect) {
      return Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius ?? context.radiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? context.colorScheme.surface.withOpacity(0.1),
                borderRadius: borderRadius ?? context.radiusLarge,
                border: Border.all(
                  color: context.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap != null ? () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  } : null,
                  borderRadius: borderRadius ?? context.radiusLarge,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ).animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? context.radiusLarge,
        boxShadow: boxShadow ?? context.shadowMedium,
      ),
      child: Material(
        color: backgroundColor ?? context.colorScheme.surface,
        borderRadius: borderRadius ?? context.radiusLarge,
        elevation: elevation ?? 0,
        child: InkWell(
          onTap: onTap != null ? () {
            HapticFeedback.lightImpact();
            onTap!();
          } : null,
          borderRadius: borderRadius ?? context.radiusLarge,
          child: content,
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// Modern Button with Animations
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonStyle? style;
  final bool filled;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style,
    this.filled = true,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.foregroundColor ?? context.colorScheme.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.text),
            ],
          );

    Widget button;
    
    if (widget.outlined) {
      button = OutlinedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: widget.style ?? OutlinedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor ?? context.colorScheme.primary,
          minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
          padding: widget.padding,
        ),
        child: buttonChild,
      );
    } else if (widget.filled) {
      button = FilledButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: widget.style ?? FilledButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? context.colorScheme.primary,
          foregroundColor: widget.foregroundColor ?? context.colorScheme.onPrimary,
          minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
          padding: widget.padding,
        ),
        child: buttonChild,
      );
    } else {
      button = TextButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: widget.style ?? TextButton.styleFrom(
          foregroundColor: widget.foregroundColor ?? context.colorScheme.primary,
          minimumSize: Size(widget.width ?? 0, widget.height ?? 48),
          padding: widget.padding,
        ),
        child: buttonChild,
      );
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading ? _handleTapDown : null,
      onTapUp: widget.onPressed != null && !widget.isLoading ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading ? _handleTapCancel : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: button,
          );
        },
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.1, end: 0);
  }
}

// Modern Text Field
class ModernTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final int? maxLines;
  final bool filled;
  final Color? fillColor;
  final bool readOnly;
  final VoidCallback? onTap;

  const ModernTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.maxLines = 1,
    this.filled = true,
    this.fillColor,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: context.radiusMedium,
        boxShadow: _isFocused ? context.shadowMedium : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        autofocus: widget.autofocus,
        maxLines: widget.maxLines,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        style: context.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          filled: widget.filled,
          fillColor: widget.fillColor ?? context.colorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: context.radiusMedium,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: context.radiusMedium,
            borderSide: BorderSide(
              color: context.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: context.radiusMedium,
            borderSide: BorderSide(
              color: context.colorScheme.error,
              width: 1,
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: -0.1, end: 0);
  }
}

// Loading Shimmer
class ModernShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const ModernShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: context.colorScheme.surfaceVariant,
        highlightColor: context.colorScheme.surface,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? 100,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceVariant,
            borderRadius: borderRadius ?? context.radiusMedium,
          ),
        ),
      ),
    );
  }
}

// Modern App Bar
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final bool implyLeading;

  const ModernAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.implyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(
        title!,
        style: context.textTheme.titleLarge,
      ) : null,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      automaticallyImplyLeading: implyLeading,
      scrolledUnderElevation: 3,
      surfaceTintColor: context.colorScheme.surfaceTint,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Modern Chip
class ModernChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color? backgroundColor;
  final Color? selectedColor;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null ? () {
        HapticFeedback.selectionClick();
        onTap!();
      } : null,
      borderRadius: context.radiusCircular,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected 
            ? (selectedColor ?? context.colorScheme.primaryContainer)
            : (backgroundColor ?? context.colorScheme.surfaceVariant.withOpacity(0.5)),
          borderRadius: context.radiusCircular,
          border: Border.all(
            color: selected 
              ? context.colorScheme.primary
              : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected 
                  ? context.colorScheme.onPrimaryContainer
                  : context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected 
                  ? context.colorScheme.onPrimaryContainer
                  : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

// Modern Bottom Sheet
class ModernBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const ModernBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    EdgeInsetsGeometry? padding,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernBottomSheet(
        title: title,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: context.radiusCircular,
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 16),
            Text(
              title!,
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: padding ?? const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    ).animate()
      .slideY(begin: 0.2, end: 0, duration: 300.ms)
      .fadeIn();
  }
}