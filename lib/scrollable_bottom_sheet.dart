import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_bottom_sheet/scrollable_controller.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

typedef AnimationCallback = void Function(double value);
typedef StateCallback = void Function(ScrollState state);

enum ScrollDirection { none, up, down }
enum ScrollState { full, half, minimum }

class ScrollableBottomSheetByContent extends StatefulWidget {
    
    final VoidCallback loadingCallback;
    bool isLoading;
    
    final Widget header;
    final ScrollableController controller;
    final StateCallback callback;
    final bool snapAbove;
    final bool snapBelow;
    final bool autoPop;
    final ScrollState scrollTo;
    /// header 滚出窗口后, hoverHeaderWidget会出现在顶部, 通过hoverHeaderWidget可以实现header的悬停功能
    final Widget hoverHeaderWidget;
    /// 存放在 custom sliver中的可滚动的widgets
    final List<Widget> sliverList;

    ScrollableBottomSheetByContent(this.header, this.sliverList,
                                   {ScrollableController controller, bool snapAbove, bool snapBelow, bool autoPop, this.callback, ScrollState scrollTo, this.hoverHeaderWidget,
                                       this.loadingCallback, this.isLoading = false})
        : this.controller = controller ?? ScrollableController(),
            this.snapAbove = snapAbove ?? true,
            this.snapBelow = snapBelow ?? true,
            this.autoPop = autoPop ?? true,
            this.scrollTo = scrollTo ?? ScrollState.minimum;
    
    @override
    State<StatefulWidget> createState() => _ScrollableBottomSheetByContentState();
}

class _ScrollableBottomSheetByContentState extends State<ScrollableBottomSheetByContent> {
    BuildContext _headerContext;
    
    @override
    void initState() {
        // TODO: implement initState
        super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.controller.setMinimumHeight(_headerContext.size.height);
            //widget.controller.setHalfHeight(_headerContext.size.height + _contentContext.size.height);
            
            if (widget.scrollTo == ScrollState.minimum) {
                widget.controller.animateToMinimum(context);
            } else if (widget.scrollTo == ScrollState.half) {
                widget.controller.animateToHalf(context);
            } else if (widget.scrollTo == ScrollState.full) {
                widget.controller.animateToFull(context);
            }
        });
    }
    
    @override
    Widget build(BuildContext context) {
        return ScrollableBottomSheet(
            controller: widget.controller,
            snapAbove: widget.snapAbove,
            snapBelow: widget.snapBelow,
            autoPop: widget.autoPop,
            callback: widget.callback,
            headerWidget: Builder(
                builder: (BuildContext context) {
                    _headerContext = context;
                    return widget.header;
                },
            ),
            sliverList: widget.sliverList,
            halfHeight: 0.0,
            mayExceedChildHeight: true,
            hoverHeaderWidget: this.widget.hoverHeaderWidget,
            loadingCallback: widget.loadingCallback,
            isLoading: widget.isLoading,
        );
    }
}

class ScrollableBottomSheet extends StatefulWidget {
    /// We change from GlobalKey system to controller system
    /// Whenever parent wants to animate bottom sheet to certain position
    /// for example minimum / half / full, it is executed by this controller
    ///
    /// See [ScrollableInterface]
    final ScrollableController controller;

    bool isLoading;
    
    final VoidCallback loadingCallback;
    
    /// The Bottom Sheet's height when first open
    /// Must not be null
    final double halfHeight;
    
    /// The content inside Bottom Sheet
    /// Must not be null
    final Widget headerWidget;

    final Widget hoverHeaderWidget;
    
    /// If this true, if user drag Bottom Sheet in between [halfHeight] and
    /// maximum height, the Bottom Sheet will be snapped according to last scroll
    /// direction user made
    ///
    /// If this false, there will be no snapping automatically
    ///
    /// See [ScrollDirection], [minimumHeight]
    final bool snapAbove;
    
    /// If this true, if user drag Bottom Sheet in between [halfHeight] and
    /// [minimumHeight], the Bottom Sheet will be snapped according to last scroll
    /// direction user made
    ///
    /// If this false, there will be no snapping automatically
    ///
    /// See [ScrollDirection], [minimumHeight]
    final bool snapBelow;
    
    /// If this true, if user drag Bottom Sheet until [minimumHeight],
    /// Navigation.pop will be called automatically
    ///
    /// If this false, there will be no popping automatically
    ///
    /// See [minimumHeight]
    final bool autoPop;
    
    /// If this value is not null, this value will replace 0.0 as minimum height,
    /// and there will be no automatic popping when user scroll Bottom Sheet
    /// between [halfHeight] and [minimumHeight]
    ///
    /// You can pop it manually by using [Navigator]
    ///
    /// ```
    /// Navigator.pop(context);
    /// ```
    ///
    /// See [halfHeight]
    final double minimumHeight;
    
    /// Scroll State callback, it triggered every time bottom sheet reach for
    /// fullHeight / [halfHeight] / [minimumHeight]
    ///
    /// See [ScrollState], [halfHeight], [minimumHeight]
    final StateCallback callback;
    
    /// To determine which position the bottom sheet should be in the first push
    /// between fullHeight / [halfHeight] / [minimumHeight]
    ///
    /// See [ScrollState], [halfHeight], [minimumHeight]
    final ScrollState firstScrollTo;
    
    /// If this true, fullHeight won't exceed child's height
    ///
    /// If this false, it'll always scrollable to fullscreen height
    ///
    /// See [_fullHeight]
    final bool mayExceedChildHeight;
    
    final List<Widget> sliverList;
    
    ScrollableBottomSheet({
                              ScrollableController controller,
                              @required this.halfHeight,
                              @required this.headerWidget,
                              bool snapAbove,
                              bool snapBelow,
                              bool autoPop,
                              double minimumHeight,
                              this.callback,
                              ScrollState scrollTo,
                              bool mayExceedChildHeight,
                              this.sliverList,
                              this.hoverHeaderWidget,
                              this.loadingCallback,
                              this.isLoading,
                          }): assert(headerWidget != null),
            this.controller = controller ?? ScrollableController(),
            this.minimumHeight = minimumHeight ?? 0.0,
            this.snapAbove = snapAbove ?? true,
            this.snapBelow = snapBelow ?? true,
            this.autoPop = autoPop ?? true,
            this.firstScrollTo = scrollTo ?? ScrollState.half,
            this.mayExceedChildHeight = mayExceedChildHeight ?? false;
    
    @override
    State<StatefulWidget> createState() => _ScrollableBottomSheetState();
}

class _ScrollableBottomSheetState extends State<ScrollableBottomSheet>
    with TickerProviderStateMixin
    implements ScrollableInterface {
    double _currentHeight;
    double _minimumHeight;
    double _halfHeight;
    bool _requestToFull = false;
    double _fullHeight;
    ScrollController _scrollController = ScrollController();
    ScrollState _currentState;
    BuildContext _headerContext;
    AnimationController _activeAnimController;
    GlobalKey headerKey = GlobalKey();
    GlobalKey<HoverHeaderPanelState> hoverHeaderWidgetKey = GlobalKey<HoverHeaderPanelState>();
    
    ScrollDirection _lastScrollDirection = ScrollDirection.none;
    
    @override
    void initState() {
        super.initState();
        widget.controller.interface = this;
        
        _minimumHeight = widget.minimumHeight ?? 0.0;
        _halfHeight = widget.halfHeight ?? 0.0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
            
            _currentState = widget.firstScrollTo;
            if (widget.callback != null) widget.callback(_currentState);
        });
        this._scrollController.addListener((){
    
            RenderBox box = headerKey.currentContext.findRenderObject();
            Offset offset = box.localToGlobal(Offset.zero);
            RenderBox box2 = hoverHeaderWidgetKey.currentContext.findRenderObject();
            Offset offset2 = box2.localToGlobal(Offset.zero);
//            print("header.y=${offset.dy}, hover.y= ${offset2.dy}");
            if (offset.dy < offset2.dy) {
                hoverHeaderWidgetKey.currentState.showPanel();
//                this._floatToolBarBloc.dispatchSendFalseEvent();
            } else {
                hoverHeaderWidgetKey.currentState.hidenPanel();
//                this._floatToolBarBloc.dispatchSendTrueEvent();
            }
//            scrollableController.animateToZero(context, duration: Duration(microseconds: 1));
        
        });
    }
    
    @override
    void dispose() {
        _activeAnimController?.dispose();
        super.dispose();
    }
    
    @override
    Widget build(BuildContext context) {
        if (_requestToFull) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                _animateTo(_fullHeight);
            });
            _requestToFull = false;
        }
        
        Widget child = LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
//            print("容器最size:(${constraints.maxWidth}, ${constraints.maxHeight})");
            
            _fullHeight ??= constraints.maxHeight;
            
            //for the first run
            if (_currentHeight == null) {
                _currentHeight = widget.firstScrollTo == ScrollState.half
                    ? _halfHeight
                    : widget.firstScrollTo == ScrollState.full ? _fullHeight : widget.minimumHeight;
            } else if (_currentHeight < widget.minimumHeight) {
                _currentHeight = widget.minimumHeight;
            }
            
            _currentHeight = _currentHeight.clamp(_minimumHeight, _fullHeight);
            List<Widget> list = List.from(widget.sliverList);
            list.insert(0, SliverToBoxAdapter(
                child: Container(
                    key: this.headerKey,
                    child: widget.headerWidget,
                ),
            ));
            
            return Stack(
                children: <Widget>[
                    Container(
                        height: _currentHeight,
                        child: GestureDetector(
                            onVerticalDragEnd: _dragEnd,
                            onVerticalDragDown: (DragDownDetails details) {
                                _hold = _scrollController.position.hold(_disposeHold);
                            },
                            onVerticalDragCancel: () {
                                _drag?.cancel();
                                _hold?.cancel();
                            },
                            onVerticalDragUpdate: _dragUpdate,
                            onVerticalDragStart: _dragStart,
                            child: LazyLoadScrollView(
                                onEndOfPage: () {
                                    widget.loadingCallback();
                                }, // The callback when reaching the end of the list
                                scrollOffset: 100, // Pixels from the bottom that should trigger a callback
                                isLoading: widget.isLoading,
                                child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: const NeverScrollableScrollPhysics(),
                                    slivers: list,
                                ),
                            ),
                            
                        )),
                    Positioned(
                        child: GestureDetector(
                            onVerticalDragEnd: _dragHoverHeaderEnd,
                            onVerticalDragDown: (DragDownDetails details) {
                                _hold = _scrollController.position.hold(_disposeHold);
                            },
                            onVerticalDragCancel: () {
                                _drag?.cancel();
                                _hold?.cancel();
                            },
                            onVerticalDragUpdate: (DragUpdateDetails details) {
                                _dragHoverHeaderUpdate(details);
                            },
                            onVerticalDragStart: (DragStartDetails details) {
                                _dragStart(details);
                            },
                            child: HoverHeaderPanel(
                                child: widget.hoverHeaderWidget,
                                key: hoverHeaderWidgetKey,
                            ),
                        ),
                        top: 0,
                        right: 0,
                        left: 0,
                    ),
                ],
            );
        });
        
        return child;
    }
    
    void _dragStart(DragStartDetails details) {
        
//        print("dragStart: ${details.globalPosition}");
        if (_scrollController.position.maxScrollExtent > 0.0)
            _drag = _scrollController.position.drag(details, _disposeDrag);
    }
    
    void _dragUpdate(DragUpdateDetails details) {
//        print("dragUpdate: ${details.globalPosition}");
        if (details.primaryDelta > 0) {
            // scroll downward
            _lastScrollDirection = ScrollDirection.down;
            
            if (_scrollController.offset <= 0.0) {
                if (_currentHeight > 0.0) {
                    if (this.mounted) {
//                        print("1");
                        setState(() {
                            _currentHeight += details.primaryDelta * -1;
                        });
                    }
                }
            }
        } else if (details.primaryDelta < 0) {
            // scroll upward
            _lastScrollDirection = ScrollDirection.up;
            
            if (_currentHeight < _fullHeight) {
                if (this.mounted) {
//                    print("2");
                    setState(() {
                        _currentHeight += details.primaryDelta * -1;
                    });
                }
            }
        }
        
        if (_currentHeight >= _fullHeight) {
            DragUpdateDetails d = details;
            
            if (_scrollController.offset + -d.primaryDelta < 0.0) {
//                print("3");
                Offset newGlobalPosition = Offset(
                    details.globalPosition.dx, details.globalPosition.dy + -(d.primaryDelta) + _scrollController.offset);
                Offset newDelta = Offset(details.delta.dx, _scrollController.offset);
                
                d = DragUpdateDetails(
                    delta: newDelta,
                    primaryDelta: _scrollController.offset,
                    globalPosition: newGlobalPosition,
                    sourceTimeStamp: details.sourceTimeStamp);
            }
            
            _drag?.update(d);
        }
    }
    
    void _dragEnd(DragEndDetails details) {
        
//        print("DragEnd: ${details.velocity}");
        double targetHeight;
        
        if (_scrollController.position.pixels < 0.0) {
//            print("10");
            _scrollController.position
                .animateTo(0.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
        }
        
        if (_currentHeight <= _halfHeight) {
            if (widget.snapBelow && _scrollController.hasClients && _scrollController.position.pixels <= 0) {
//                print("11");
                if (_lastScrollDirection == ScrollDirection.down) {
                    targetHeight = _minimumHeight;
                } else {
                    targetHeight = _halfHeight;
                }
            }
        } else {
            if (widget.snapAbove && _scrollController.hasClients && _scrollController.position.pixels <= 0) {
//                print("12");
                if (_lastScrollDirection == ScrollDirection.down) {
                    targetHeight = _halfHeight;
                } else {
                    targetHeight = _fullHeight;
                }
            }
        }
        
        if (targetHeight != null) {
            
            _animateTo(targetHeight, onComplete: () {
                if ((targetHeight == 0.0 || targetHeight == _minimumHeight) && widget.autoPop) Navigator.pop(context);
            });
        }
        
        _lastScrollDirection = ScrollDirection.none;
        
        if (_currentHeight >= _fullHeight && _currentState != ScrollState.full) {
            _currentState = ScrollState.full;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentState == ScrollState.full && _currentHeight < _halfHeight) {
            _currentState = ScrollState.half;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentState == ScrollState.minimum && _currentHeight >= _halfHeight) {
            _currentState = ScrollState.half;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentHeight <= widget.minimumHeight && _currentState != ScrollState.minimum) {
            _currentState = ScrollState.minimum;
            if (widget.callback != null) widget.callback(_currentState);
        }
        if (_currentHeight >= _fullHeight) {
            _drag?.end(details);
        } else {
            _drag?.cancel();
        }
    }

    void _dragHoverHeaderUpdate(DragUpdateDetails details) {

        if (details.primaryDelta > 0) {
            // scroll downward
            _lastScrollDirection = ScrollDirection.down;

            if (_currentHeight > 0.0) {
                if (this.mounted) {
//                    print("1");
                    setState(() {
                        _currentHeight += details.primaryDelta * -1;
                    });
                }
            }
        } else if (details.primaryDelta < 0) {
            // scroll upward
            _lastScrollDirection = ScrollDirection.up;
        
            if (_currentHeight < _fullHeight) {
                if (this.mounted) {
//                    print("2");
                    setState(() {
                        _currentHeight += details.primaryDelta * -1;
                    });
                }
            }
        }
    
        if (_currentHeight >= _fullHeight) {
            DragUpdateDetails d = details;
        
            if (_scrollController.offset + -d.primaryDelta < 0.0) {
//                print("3");
                Offset newGlobalPosition = Offset(
                    details.globalPosition.dx, details.globalPosition.dy + -(d.primaryDelta) + _scrollController.offset);
                Offset newDelta = Offset(details.delta.dx, _scrollController.offset);
            
                d = DragUpdateDetails(
                    delta: newDelta,
                    primaryDelta: _scrollController.offset,
                    globalPosition: newGlobalPosition,
                    sourceTimeStamp: details.sourceTimeStamp);
            }
        
            _drag?.update(d);
        }
    }

    void _dragHoverHeaderEnd(DragEndDetails details) {
    
//        print("DragEnd: ${details.velocity}");
        double targetHeight;
    
//        if (_scrollController.position.pixels < 0.0) {
//            print("10");
//            _scrollController.position
//                .animateTo(0.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
//        }
        bool needScrollToTop = true;
    
        if (_currentHeight <= _halfHeight) {
            if (widget.snapBelow && _scrollController.hasClients) {
//                print("11");
                if (_lastScrollDirection == ScrollDirection.down) {
                    targetHeight = _minimumHeight;
                } else {
                    targetHeight = _halfHeight;
                }
            }
        } else {
            if (widget.snapAbove && _scrollController.hasClients) {
//                print("12");
                if (_lastScrollDirection == ScrollDirection.down) {
                    needScrollToTop = true;
                    targetHeight = _halfHeight;
                } else {
                    needScrollToTop = false;
                    targetHeight = _fullHeight;
                }
            }
        }
    
        if (targetHeight != null) {
        
            _animateTo(targetHeight, needScrollToTop: needScrollToTop, onComplete: () {
                if ((targetHeight == 0.0 || targetHeight == _minimumHeight) && widget.autoPop) Navigator.pop(context);
            });
        }
    
        _lastScrollDirection = ScrollDirection.none;
    
        if (_currentHeight >= _fullHeight && _currentState != ScrollState.full) {
            _currentState = ScrollState.full;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentState == ScrollState.full && _currentHeight < _halfHeight) {
            _currentState = ScrollState.half;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentState == ScrollState.minimum && _currentHeight >= _halfHeight) {
            _currentState = ScrollState.half;
            if (widget.callback != null) widget.callback(_currentState);
        } else if (_currentHeight <= widget.minimumHeight && _currentState != ScrollState.minimum) {
            _currentState = ScrollState.minimum;
            if (widget.callback != null) widget.callback(_currentState);
        }
        if (_currentHeight >= _fullHeight) {
            _drag?.end(details);
        } else {
            _drag?.cancel();
        }
    }
    
    Drag _drag;
    ScrollHoldController _hold;
    
    void _disposeDrag() {
        _drag = null;
    }
    
    void _disposeHold() {
        _hold = null;
    }
    
    /// animate current Bottom Sheet to [minimumHeight] (if specified)
    /// you can call this method from Global Key
    ///
    /// See [example/main.dart] for example
    @override
    void animateToMinimum(BuildContext context, {bool willPop = false, Duration duration}) {
        if (widget.minimumHeight == null) return;
        
        _animateTo(_minimumHeight, duration: duration, onComplete: () {
            if (willPop) Navigator.pop(context);
        });
    }
    
    /// animate current Bottom Sheet to 0.0
    /// you can call this method from Global Key
    ///
    /// See [example/main.dart] for example
    @override
    void animateToZero(BuildContext context, {bool willPop = false, Duration duration}) {
        _animateTo(0.0, duration: duration, onComplete: () {
            if (willPop) Navigator.pop(context);
        });
    }
    
    /// animate current Bottom Sheet to initialHeight
    /// you can call this method from Global Key
    ///
    /// See [example/main.dart] for example
    @override
    void animateToHalf(BuildContext context, {Duration duration}) {
        _animateTo(_halfHeight, duration: duration);
    }
    
    /// animate current Bottom Sheet to maximum height available
    /// you can call this method from Global Key
    ///
    /// See [example/main.dart] for example
    @override
    void animateToFull(BuildContext context, {Duration duration}) {
        setState(() {
            _requestToFull = true;
        });
    }
    
    _animateTo(double targetHeight, {bool needScrollToTop = true, VoidCallback onComplete, Duration duration = const Duration(milliseconds: 200)}) {
        if (!this.mounted) return;
        
        if (_scrollController.hasClients && _scrollController.position.pixels > 0 && needScrollToTop) {
            _scrollController.animateTo(0.0, duration: duration, curve: Curves.ease);
        }
        
        AnimationController animationController = AnimationController(duration: duration, vsync: this);
        
        _activeAnimController = animationController;
        
        var animation = CurvedAnimation(parent: animationController, curve: Interval(0.0, 1.0, curve: Curves.ease));
        
        Animation<double> zeroScale = Tween<double>(begin: _currentHeight, end: targetHeight).animate(animation);
        
        animationController.forward();
        
        var listener = () {
            if (this.mounted) {
                setState(() {
                    _currentHeight = zeroScale.value;
                    
                    if (zeroScale.value == targetHeight && zeroScale.status == AnimationStatus.completed) {
                        if (targetHeight == _fullHeight) {
                            _currentState = ScrollState.full;
                        } else if (targetHeight == _halfHeight) {
                            _currentState = ScrollState.half;
                        } else if (targetHeight == widget.minimumHeight) {
                            _currentState = ScrollState.minimum;
                        }
                        
                        if (onComplete != null) onComplete();
                        animationController.dispose();
                        _activeAnimController = null;
                        
                        if (widget.callback != null) widget.callback(_currentState);
                    }
                });
            }
        };
        
        zeroScale.addListener(listener);
    }
    
    @override
    void setHalfHeight(double newHalfHeight) {
        _halfHeight = newHalfHeight;
    }
    
    @override
    void setMinimumHeight(double newMinimumHeight) {
        _minimumHeight = newMinimumHeight;
    }
    
    void setFullHeight(double newFullHeight) {
        
        _fullHeight = newFullHeight;
    }

    @override
    void setScrollState(ScrollState sState) {
    
        setState(() {

            if (sState == ScrollState.full) {
                _currentState = ScrollState.full;
                _currentHeight = _fullHeight;
            } else if (sState == ScrollState.minimum) {
                _currentState = ScrollState.minimum;
                _currentHeight = _minimumHeight;
            } else {
                _currentState = ScrollState.half;
                _currentHeight = _halfHeight;
            }
        });
    }
    
}

class HoverHeaderPanel extends StatefulWidget {
    
    
    Widget child;

    HoverHeaderPanel({Key key,@required this.child}) : assert(child != null), super(key:key);
    
    @override
    HoverHeaderPanelState createState() => new HoverHeaderPanelState();
}

class HoverHeaderPanelState extends State<HoverHeaderPanel> {
    
    
    bool panelNeedShow = false;
    
    @override
    Widget build(BuildContext context) {
        return AnimatedOpacity(
            opacity: this.panelNeedShow ? 1 : 0,
            duration: Duration(seconds: 0),
            child: widget.child
        );
    }
    
    @override
    void initState() {
        // TODO: implement initState
        super.initState();
    }
    
    @override
    void dispose() {
        // TODO: implement dispose
        super.dispose();
    }
    
    void showPanel() {
        panelNeedShow = true;
        this.setState((){});
    }
    
    void hidenPanel() {
        panelNeedShow = false;
        this.setState((){});
        
    }
    
}
