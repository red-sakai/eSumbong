import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/cases/domain/case_event.dart';

class CaseTimeline extends StatefulWidget {
  const CaseTimeline({super.key, required this.events});

  final List<CaseEvent> events;

  @override
  State<CaseTimeline> createState() => _CaseTimelineState();
}

class _CaseTimelineState extends State<CaseTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CaseTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const Text('No timeline events yet.');
    }

    final sortedEvents = List<CaseEvent>.from(widget.events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: List<Widget>.generate(sortedEvents.length, (index) {
        final event = sortedEvents[index];
        final isLast = index == sortedEvents.length - 1;
        final tone = _toneFor(event.title);
        final start = (index * 0.12).clamp(0.0, 0.75);
        final end = (start + 0.25).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(animation),
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: tone.color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(tone.icon, size: 12, color: tone.color),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 68,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: tone.color.withValues(alpha: 0.26),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: tone.color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tone.color.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tone.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  DateFormat.yMMMd().add_jm().format(
                                    event.timestamp,
                                  ),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: tone.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(event.description),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  _TimelineTone _toneFor(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('file')) {
      return const _TimelineTone(Color(0xFF0369A1), Icons.upload_file_rounded);
    }
    if (normalized.contains('summons')) {
      return const _TimelineTone(Color(0xFF4F46E5), Icons.campaign_rounded);
    }
    if (normalized.contains('hearing')) {
      return const _TimelineTone(
        Color(0xFF0F766E),
        Icons.event_available_rounded,
      );
    }
    if (normalized.contains('no show')) {
      return const _TimelineTone(Color(0xFFB45309), Icons.person_off_rounded);
    }
    if (normalized.contains('certificate') || normalized.contains('cfa')) {
      return const _TimelineTone(Color(0xFF15803D), Icons.verified_rounded);
    }

    return const _TimelineTone(Color(0xFF64748B), Icons.circle_rounded);
  }
}

class _TimelineTone {
  const _TimelineTone(this.color, this.icon);

  final Color color;
  final IconData icon;
}
