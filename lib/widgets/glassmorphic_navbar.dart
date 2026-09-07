// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:axiomos_workforce/constants/colors.dart';
// import 'package:axiomos_workforce/widgets/glassmorphic_container.dart';

// class CustomNavBar extends ConsumerWidget {
//   const CustomNavBar({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(30),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//         child: GlassmorphicContainer(
//           height: 60,
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           // decoration: BoxDecoration(
//           //   color: Colors.white.withOpacity(0.7),
//           //   borderRadius: BorderRadius.circular(30),
//           // ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: const [
//               NavItem(
//                 index: 0,
//                 icon: Icons.grid_view_rounded,
//                 label: "Dashboard",
//               ),
//               NavItem(index: 1, icon: Icons.home_rounded, label: "Home"),
//               NavItem(
//                 index: 3,
//                 icon: Icons.notifications,
//                 label: "Notifications",
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class NavItem extends ConsumerWidget {
//   final int index;
//   final IconData icon;
//   final String? label;

//   const NavItem({
//     super.key,
//     required this.index,
//     required this.icon,
//     this.label,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final currentIndex = ref.watch(navIndexProvider);
//     final isActive = index == currentIndex;

//     return GestureDetector(
//       onTap: () {
//         ref.read(navIndexProvider.notifier).setIndex(index);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         padding: isActive
//             ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
//             : EdgeInsets.zero,
//         decoration: BoxDecoration(
//           color: isActive ? Colors.white : Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: isActive ? AppColors.appMainDark : Colors.black54,
//             ),
//             const SizedBox(width: 6),
//             Text(
//               label!,
//               style: TextStyle(
//                 color: isActive ? AppColors.appMainDark : Colors.black54,
//                 fontSize: isActive ? 16 : 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// //Nav bar provider
// final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(
//   NavIndexNotifier.new,
// );

// class NavIndexNotifier extends Notifier<int> {
//   @override
//   int build() => 1;

//   void setIndex(int index) => state = index;
// }
