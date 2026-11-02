import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/connection_state.dart';

class OledPowerButton extends StatefulWidget {
  final VpnConnectionStatus status;
  final VoidCallback onTap;

  const OledPowerButton({
    super.key,
    required this.status,
    required this.onTap,
  });

  @override
  State<OledPowerButton> createState() => _OledPowerButtonState();
}

class _OledPowerButtonState extends State<OledPowerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant OledPowerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.status.isConnecting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.status) {
      case VpnConnectionStatus.connected:
        return AppColors.connected;
      case VpnConnectionStatus.connecting:
      case VpnConnectionStatus.disconnecting:
        return AppColors.connecting;
      case VpnConnectionStatus.disconnected:
      default:
        return Colors.transparent;
    }
  }

  Color get _ringColor {
    switch (widget.status) {
      case VpnConnectionStatus.connected:
        return AppColors.connected;
      case VpnConnectionStatus.connecting:
      case VpnConnectionStatus.disconnecting:
        return AppColors.connecting;
      case VpnConnectionStatus.disconnected:
      default:
        return AppColors.borderSubtle;
    }
  }

  String _getStatusLabel(BuildContext context) {
    final tr = context.tr;
    switch (widget.status) {
      case VpnConnectionStatus.connected:
        return tr.vpnConnected.toUpperCase();
      case VpnConnectionStatus.connecting:
        return tr.vpnConnecting.toUpperCase();
      case VpnConnectionStatus.disconnecting:
        return tr.vpnDisconnecting.toUpperCase();
      case VpnConnectionStatus.disconnected:
        return tr.vpnDisconnected.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double size = 180;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = widget.status.isConnecting ? _pulseAnimation.value : 1.0;
          return Transform.scale(
            scale: _isPressed ? scale * 0.95 : scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfacePrimary,
              border: Border.all(color: _ringColor, width: 2),
              boxShadow: [
                if (widget.status.isConnected)
                  BoxShadow(
                    color: _glowColor.withOpacity(0.35),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                if (widget.status.isConnecting)
                  BoxShadow(
                    color: _glowColor.withOpacity(0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner concentric groove
                Container(
                  width: size - 32,
                  height: size - 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceSecondary,
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                ),
                // Center icon and indicator
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.power_settings_new_rounded,
                      size: 54,
                      color: widget.status.isConnected
                          ? AppColors.connected
                          : (widget.status.isConnecting
                              ? AppColors.connecting
                              : AppColors.disconnected),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusLabel(context),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: widget.status.isConnected
                            ? AppColors.connected
                            : (widget.status.isConnecting
                                ? AppColors.connecting
                                : AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
