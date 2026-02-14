import 'dart:async';
import 'package:flutter/material.dart';

class AuctionListTimer extends StatefulWidget {
  final DateTime endTime;
  final bool compact;
  final Color? color;

  const AuctionListTimer({
    super.key,
    required this.endTime,
    this.compact = false,
    this.color,
  });

  @override
  State<AuctionListTimer> createState() => _AuctionListTimerState();
}

class _AuctionListTimerState extends State<AuctionListTimer> {
  late Timer _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _diff = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;

    final now = DateTime.now();
    setState(() {
      _diff = widget.endTime.difference(now);
    });

    if (_diff.isNegative) {
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_diff.isNegative) {
      return Text(
        "Ended",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: widget.compact ? 12 : 14,
        ),
      );
    }

    String hours = _diff.inHours.toString().padLeft(2, '0');
    String minutes = (_diff.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_diff.inSeconds % 60).toString().padLeft(2, '0');

    // Urgency Logic: Red if less than 1 hour remaining
    final bool isUrgent = _diff.inHours < 1;
    final Color displayColor = isUrgent
        ? Colors.red
        : (widget.color ?? Colors.black);

    final Color labelColor = widget.color ?? Colors.grey;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: displayColor),
          const SizedBox(width: 4),
          Text(
            "$hours:$minutes:$seconds",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: displayColor,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("Ends in", style: TextStyle(color: labelColor, fontSize: 12)),
        Text(
          "$hours:$minutes:$seconds",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}
