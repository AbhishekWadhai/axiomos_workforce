import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildShimmerCard() {
  return Shimmer.fromColors(
    period: Duration(milliseconds: 800),
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: ListTile(
          title: Container(
            width: double.infinity,
            height: 16.0,
            color: Colors.white70,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 150.0,
                height: 14.0,
                color: Colors.white70,
              ),
              const SizedBox(height: 4),
              Container(
                width: 100.0,
                height: 14.0,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
