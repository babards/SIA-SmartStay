import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/property_model.dart';
import '../services/weather_service.dart';
import '../screens/properties/property_detail_screen.dart';
import 'weather_popup.dart';

class HoverWeatherPopup extends StatefulWidget {
  final PropertyModel property;
  final Widget child;
  final Function(PropertyModel)? onViewDetails;

  const HoverWeatherPopup({
    Key? key,
    required this.property,
    required this.child,
    this.onViewDetails,
  }) : super(key: key);

  @override
  _HoverWeatherPopupState createState() => _HoverWeatherPopupState();
}

class _HoverWeatherPopupState extends State<HoverWeatherPopup>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isHovering = false;
  WeatherData? _weather;
  List<WeatherData>? _forecast;
  bool _isLoading = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 120),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _hideTimer?.cancel();
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (_animationController.isAnimating || _animationController.value > 0) {
      _animationController.reverse();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: 150), () {
      if (!_isHovering && _overlayEntry != null) {
        _removeOverlay();
      }
    });
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  Offset _getOverlayPosition(BuildContext context, Offset markerPosition) {
    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 280.0;
    const popupHeight = 400.0;

    double left = markerPosition.dx - popupWidth / 2;
    double top = markerPosition.dy - popupHeight - 20;

    if (left < 10) left = 10;
    if (left + popupWidth > screenSize.width - 10) {
      left = screenSize.width - popupWidth - 10;
    }
    if (top < 10) {
      top = markerPosition.dy + 40;
    }

    return Offset(left, top);
  }

  void _showOverlay(BuildContext context, Offset position) async {
    if (_overlayEntry != null || !_isHovering) return;

    if (!_isLoading) {
      setState(() => _isLoading = true);
      final weatherService =
          Provider.of<WeatherService>(context, listen: false);

      try {
        final weather = await weatherService.getCurrentWeather(
          widget.property.latitude,
          widget.property.longitude,
        );
        final forecast = await weatherService.getWeatherForecast(
          widget.property.latitude,
          widget.property.longitude,
        );

        if (mounted) {
          setState(() {
            _weather = weather;
            _forecast = forecast;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _getOverlayPosition(context, position).dx,
        top: _getOverlayPosition(context, position).dy,
        child: Material(
          color: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) => _cancelHide(),
            onExit: (_) => _scheduleHide(),
            child: FadeTransition(
              opacity: _animation,
              child: WeatherPopup(
                property: widget.property,
                weather: _weather,
                forecast: _forecast,
                onViewDetails: () {
                  _removeOverlay();
                  if (widget.onViewDetails != null) {
                    widget.onViewDetails!(widget.property);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PropertyDetailScreen(property: widget.property),
                      ),
                    );
                  }
                },
                onClose: () {
                  _removeOverlay();
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    if (!_animationController.isAnimating) {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        _cancelHide();
        if (!_isHovering && _overlayEntry == null) {
          setState(() => _isHovering = true);
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset topLeft = renderBox.localToGlobal(Offset.zero);
          final Size size = renderBox.size;
          // Anchor at the horizontal center, top edge of the marker
          final Offset markerCenterTop = topLeft + Offset(size.width / 2, 0);
          _showOverlay(context, markerCenterTop);
        }
      },
      onExit: (event) {
        setState(() => _isHovering = false);
        _scheduleHide();
      },
      child: Container(
        padding: EdgeInsets.all(8),
        child: widget.child,
      ),
    );
  }
}
