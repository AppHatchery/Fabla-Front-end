import 'package:flutter/material.dart';

class CustomToggleButtons extends StatefulWidget {
  final List<bool> isSelected;
  final List<Widget> children;
  final void Function(int) onPressed;
  final double borderRadius;
  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;

  const CustomToggleButtons({
    Key? key,
    required this.isSelected,
    required this.children,
    required this.onPressed,
    this.borderRadius = 12,
    required this.selectedBackgroundColor,
    required this.unselectedBackgroundColor,
  }) : super(key: key);

  @override
  State<CustomToggleButtons> createState() => _CustomToggleButtonsState();
}

class _CustomToggleButtonsState extends State<CustomToggleButtons> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        children: List.generate(widget.children.length, (index) {
          return GestureDetector(
            onTap: () {
              widget.onPressed(index);
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected[index]
                    ? widget.selectedBackgroundColor
                    : widget.unselectedBackgroundColor,
                border: Border.all(
                  color: widget.isSelected[index]
                      ? widget.selectedBackgroundColor
                      : widget.unselectedBackgroundColor,
                  width: 0.3,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.children[index],
              ),
            ),
          );
        }),
      ),
    );
  }
}