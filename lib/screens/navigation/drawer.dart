import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/models.dart';
import '/widgets/waypoint_card.dart';

class NavigationDrawer extends StatefulWidget {
  const NavigationDrawer({super.key, required this.tour});

  final TourModel tour;

  @override
  State<NavigationDrawer> createState() => NavigationDrawerState();
}

class NavigationDrawerState extends State<NavigationDrawer>
    with SingleTickerProviderStateMixin {
  static const _curve = Cubic(0.65, 0.0, 0.35, 1.0);
  static const _invCurve = Cubic(0.0, 0.65, 1.0, 0.35);

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: _curve,
  );

  Offset? _dragStart;
  double? _dragStartSize;

  double _innerSize = 0;
  double _expandedSize = 0;

  @override
  Widget build(BuildContext context) {
    const handleHeight = 8.0;
    const handleWidth = 50.0;

    return ConstraintsTransformBox(
      constraintsTransform: (c) => BoxConstraints(
        minWidth: c.minWidth,
        maxWidth: c.maxWidth,
        minHeight: 0,
        maxHeight: c.maxHeight,
      ),
      alignment: Alignment.bottomCenter,
      child: LayoutBuilder(builder: (context, constraints) {
        _expandedSize = constraints.maxHeight * 0.5;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              child: GestureDetector(
                onTap: _onTap,
                onVerticalDragStart: onVerticalDragStart,
                onVerticalDragEnd: onVerticalDragEnd,
                onVerticalDragUpdate: onVerticalDragUpdate,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: UnconstrainedBox(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child:
                            SizedBox(height: handleHeight, width: handleWidth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: ClipRect(
                child: SizedBox(
                  height: _innerSize,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: _expandedSize,
                    child: Material(
                      color: const Color.fromARGB(255, 244, 244, 244),
                      child: Column(
                        children: [
                          const Divider(height: 2, thickness: 2),
                          Expanded(
                            child: NotificationListener<OverscrollNotification>(
                              onNotification: (notification) {
                                if (notification.velocity == 0 &&
                                    notification.overscroll < -2) {
                                  setState(() {
                                    var factor = _animation.value *
                                        _innerSize /
                                        _expandedSize;
                                    _controller.reverse(
                                        from: _invCurve.transform(factor));
                                  });
                                }

                                return false;
                              },
                              child: ListView(
                                children: [
                                  const SizedBox(height: 3),
                                  for (var x
                                      in widget.tour.waypoints.asMap().entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 3.0,
                                      ),
                                      child: WaypointCard(
                                        waypoint: x.value,
                                        index: x.key,
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _onTap() {
    setState(() {
      var factor = _animation.value * _innerSize / _expandedSize;

      if (factor > 0.5) {
        _controller.reverse(from: _invCurve.transform(factor));
      } else {
        _innerSize = _expandedSize;
        _controller.forward(from: _invCurve.transform(factor));
      }
    });
  }

  void onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _controller.stop();
      _dragStart = details.globalPosition;
      _dragStartSize = _innerSize = _controller.value * _innerSize;
      _controller.value = _controller.upperBound;
    });
  }

  void onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      var startFactor = _dragStartSize! / _expandedSize;
      var factor = _innerSize / _expandedSize;

      if (factor > (startFactor > 0.5 ? 0.85 : 0.15)) {
        _innerSize = _expandedSize;
        _controller.forward(from: _invCurve.transform(factor));
      } else {
        _controller.reverse(from: _invCurve.transform(factor));
      }

      _dragStart = null;
      _dragStartSize = null;
    });
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      var dragStart = _dragStart!;
      var dragStartSize = _dragStartSize!;

      var dragOffset = details.globalPosition - dragStart;

      _innerSize = clampDouble(dragStartSize - dragOffset.dy, 0, _expandedSize);
    });
  }
}
