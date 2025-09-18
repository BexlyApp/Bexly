import 'package:flutter/material.dart';

import '../constants/colors.dart';


class CustomTextField extends StatefulWidget {
  final String label;
  final IconData? icon, icon2;
  final double height;
  final bool obscureText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;

  const CustomTextField({super.key,
    required this.label,
    this.icon,
    this.icon2,
    this.height = 42,
    this.obscureText = false,

    this.controller,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textFormFieldBorderColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextFormField(

        controller: widget.controller,
        onChanged: widget.onChanged,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        style: const TextStyle(color: Colors.black54,fontSize: 16,fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: -3),
          hintStyle: const TextStyle(color: Colors.black54,fontSize: 16,fontWeight: FontWeight.w400),
          prefixIcon: Icon(
            widget.icon,
            size: 20,
            color:Colors.black54,
          ),
          suffixIcon: Icon(
            widget.icon2,
            size: 20,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
