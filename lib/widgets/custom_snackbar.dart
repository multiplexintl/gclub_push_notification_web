import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SnackbarPosition { topRight, topLeft, bottomRight, bottomLeft }

class CustomSnackbar extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onClose;

  const CustomSnackbar({
    super.key,
    required this.title,
    required this.message,
    this.backgroundColor = Colors.black87,
    this.duration = const Duration(seconds: 3),
    this.onClose,
  });

  static OverlayEntry? _overlayEntry;

  static void show({
    required String title,
    required String message,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 3),
    SnackbarPosition position = SnackbarPosition.topRight,
    VoidCallback? onClose,
  }) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(Get.overlayContext!);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SnackbarOverlay(
        position: position,
        child: CustomSnackbar(
          title: title,
          message: message,
          backgroundColor: backgroundColor,
          duration: duration,
          onClose: () {
            if (_overlayEntry?.mounted ?? false) {
              _overlayEntry?.remove();
              _overlayEntry = null;
            }
            onClose?.call();
          },
        ),
      ),
    );

    _overlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  static void close() {
    if (_overlayEntry?.mounted ?? false) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  State<CustomSnackbar> createState() => _CustomSnackbarState();
}

class _CustomSnackbarState extends State<CustomSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _entryAnimation;
  late Animation<Offset> _exitAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _entryAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _exitAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_isExiting) return;
    _isExiting = true;
    await _controller.reverse();
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSnackbarContent() {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: _dismiss,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: TweenAnimationBuilder<double>(
              duration: widget.duration,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.5),
                  ),
                  minHeight: 4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            (_isExiting ? _exitAnimation.value : _entryAnimation.value) *
                size.width;

        final opacity = _fadeAnimation.value;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: offset,
            child: _buildSnackbarContent(),
          ),
        );
      },
    );
  }
}

class _SnackbarOverlay extends StatelessWidget {
  final Widget child;
  final SnackbarPosition position;

  const _SnackbarOverlay({
    required this.child,
    this.position = SnackbarPosition.topRight,
  });

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    EdgeInsets padding;

    switch (position) {
      case SnackbarPosition.topLeft:
        alignment = Alignment.topLeft;
        padding = const EdgeInsets.only(top: 20, left: 20);
        break;
      case SnackbarPosition.topRight:
        alignment = Alignment.topRight;
        padding = const EdgeInsets.only(top: 20, right: 20);
        break;
      case SnackbarPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        padding = const EdgeInsets.only(bottom: 20, left: 20);
        break;
      case SnackbarPosition.bottomRight:
        alignment = Alignment.bottomRight;
        padding = const EdgeInsets.only(bottom: 20, right: 20);
        break;
    }

    return Positioned.fill(
      child: SafeArea(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
