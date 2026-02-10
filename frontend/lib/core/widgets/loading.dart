import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/paw_loading.json',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
      ),
    );
  }
}
