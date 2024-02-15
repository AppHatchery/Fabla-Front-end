import 'package:flutter/material.dart';

class CustomCarousel extends StatefulWidget {
  final List<Widget> pages;
  final Function(int) onPageChanged;

  CustomCarousel({required this.pages, required this.onPageChanged});

  @override
  _CustomCarouselState createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  late ScrollController _scrollController;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        int page = (_scrollController.offset /
                _scrollController.position.maxScrollExtent *
                (widget.pages.length - 1))
            .round();
        if (currentPage != page) {
          currentPage = page;
          widget.onPageChanged(currentPage);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: widget.pages[index],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}







// import 'dart:async';
// import 'package:flutter/material.dart';

// typedef OnPageChanged = Function(int page);

// class CustomCarousel extends StatefulWidget {
//   final List<Widget> pages;
//   final int initialPage;
//   final OnPageChanged onPageChanged;

//   CustomCarousel({
//     Key? key,
//     required this.pages,
//     this.initialPage = 0,
//     required this.onPageChanged,
//   }) : super(key: key);

//   @override
//   _CustomCarouselState createState() => _CustomCarouselState();
// }

// class _CustomCarouselState extends State<CustomCarousel>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Timer _autoPlayTimer;
//   int _currentPage = 0;

//   @override
//   void initState() {
//     super.initState();
//     _currentPage = widget.initialPage;
//     _animationController =
//         AnimationController(vsync: this, duration: Duration(milliseconds: 300));
//     _startAutoPlayTimer(); // Start the auto-play timer
//   }

//   @override
//   void dispose() {
//     _autoPlayTimer.cancel(); // Cancel the timer when disposing the widget
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _startAutoPlayTimer() {
//     _autoPlayTimer = Timer.periodic(Duration(seconds: 3), (timer) {
//       if (!mounted) {
//         timer.cancel();
//       } else {
//         setState(() {
//           _currentPage = (_currentPage + 1) % widget.pages.length;
//           widget.onPageChanged(_currentPage);
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: widget.pages.length,
//       itemBuilder: (context, index) {
//         return Container(
//           width: MediaQuery.of(context).size.width, // Full width of the screen
//           child: widget.pages[index],
//         );
//       },
//     );
//   }
// }
