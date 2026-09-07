// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:axiomos_workforce/constants/colors.dart';
// import 'package:axiomos_workforce/model/notification_model.dart' as custom;
// import 'package:axiomos_workforce/routes/routes_string.dart';

// class ModernNotificationTile extends StatefulWidget {
//   final custom.Notification notification;
//   final VoidCallback? onTap;
//   final VoidCallback? onMarkReadToggle;
//   final VoidCallback? onDelete;

//   const ModernNotificationTile({
//     super.key,
//     required this.notification,
//     this.onTap,
//     this.onMarkReadToggle,
//     this.onDelete,
//   });

//   @override
//   State<ModernNotificationTile> createState() => _ModernNotificationTileState();
// }

// class _ModernNotificationTileState extends State<ModernNotificationTile>
//     with TickerProviderStateMixin {
//   bool _expanded = false;

//   // small helper: short relative time (simple and dependency-free)
//   String _timeAgo(dynamic raw) {
//     if (raw == null) return '';

//     DateTime? date;

//     // Already a DateTime
//     if (raw is DateTime) {
//       date = raw;
//     }
//     // A numeric epoch (int)
//     else if (raw is int) {
//       if (raw > 1000000000000) {
//         date = DateTime.fromMillisecondsSinceEpoch(raw);
//       } else {
//         date = DateTime.fromMillisecondsSinceEpoch(raw * 1000);
//       }
//     }
//     // String: try ISO parse first, then numeric parse
//     else if (raw is String) {
//       date = DateTime.tryParse(raw);
//       if (date == null) {
//         final trimmed = raw.trim();
//         final numeric = int.tryParse(trimmed);
//         if (numeric != null) {
//           if (numeric > 1000000000000) {
//             date = DateTime.fromMillisecondsSinceEpoch(numeric);
//           } else {
//             date = DateTime.fromMillisecondsSinceEpoch(numeric * 1000);
//           }
//         }
//       }
//     }

//     if (date == null) return '';

//     final diff = DateTime.now().difference(date);
//     if (diff.inSeconds < 60) return 'now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m';
//     if (diff.inHours < 24) return '${diff.inHours}h';
//     if (diff.inDays < 7) return '${diff.inDays}d';

//     return '${date.day.toString().padLeft(2, '0')}-'
//         '${date.month.toString().padLeft(2, '0')}-'
//         '${date.year.toString().substring(2)}';
//   }

//   // Show initials when no image
//   String _initials(String s) {
//     if (s.trim().isEmpty) return '';
//     final parts = s.trim().split(' ');
//     if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
//     return (parts[0][0] + parts[1][0]).toUpperCase();
//   }

//   void _defaultNavigation() {
//     final notification = widget.notification;
//     switch (notification.source) {
//       case 'workpermit':
//       case 'uauc':
//       case 'meeting':
//       case 'specific':
//       case 'induction':
//         Get.toNamed(Routes.modulePage, arguments: [notification.source]);
//         break;
//       case 'UAUC_BulkRole':
//         Get.toNamed(Routes.modulePage, arguments: ['uauc']);
//         break;
//       default:
//         Get.toNamed(Routes.modulePage, arguments: [notification.source]);
//     }
//   }

//   String _sanitizedMessage(String? raw) {
//     final s = raw ?? '';
//     return s
//         .replaceAll(RegExp(r'(\r\n|\r|\n)+'), ' ')
//         .replaceAll(r'\n', ' ')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final notification = widget.notification;
//     final isUnread = !notification.isRead;

//     // Colors — tweak to match your brand

//     final cardColor = isUnread ? Colors.white : Colors.grey.shade50;

//     final sanitized = _sanitizedMessage(notification.message);
//     // show read-more if message is "long enough" (adjust threshold to taste)
//     final canExpand =
//         sanitized.length > 120 || sanitized.split(' ').length > 18;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () {
//           // mark read if unread (optional)
//           if (isUnread && widget.onMarkReadToggle != null)
//             widget.onMarkReadToggle!();
//           if (widget.onTap != null) {
//             widget.onTap!();
//           } else {
//             _defaultNavigation();
//           }
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//             border: Border.all(
//               color: isUnread
//                   ? Colors.blue.withOpacity(0.06)
//                   : Colors.transparent,
//             ),
//           ),
//           child: Row(
//             children: [
//               // Left accent bar
//               Container(
//                 width: 6,
//                 height: 92,
//                 decoration: BoxDecoration(
//                   color: AppColors.appMainMid,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     bottomLeft: Radius.circular(12),
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 12),

//               // Title + message + meta row
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 12.0,
//                     horizontal: 2,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Title row: title + optional unread badge / time
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment
//                             .center, // center everything vertically
//                         children: [
//                           // title - allow two lines but keep it compact
//                           Expanded(
//                             child: Text(
//                               notification.title ?? '',
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),

//                           const SizedBox(width: 8),

//                           // time chip — kept compact using Column with mainAxisSize.min
//                           Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: isUnread
//                                       ? Colors.blue.shade50
//                                       : Colors.grey.shade100,
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: isUnread
//                                         ? Colors.blue.shade100
//                                         : Colors.transparent,
//                                   ),
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   "${_timeAgo(notification.createdAt)} ago",
//                                   style: TextStyle(
//                                     color: isUnread
//                                         ? Colors.blue.shade700
//                                         : Colors.grey.shade700,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           // small gap between time and icon
//                           const SizedBox(width: 6),

//                           // expand icon or stable placeholder
//                           if (canExpand)
//                             IconButton(
//                               onPressed: () =>
//                                   setState(() => _expanded = !_expanded),
//                               padding: EdgeInsets
//                                   .zero, // remove default padding so icon lines up perfectly
//                               constraints: const BoxConstraints(
//                                 minWidth: 36,
//                                 minHeight: 36,
//                               ),
//                               icon: AnimatedRotation(
//                                 turns: _expanded ? 0.5 : 0.0,
//                                 duration: const Duration(milliseconds: 220),
//                                 child: Icon(
//                                   Icons.keyboard_arrow_down_rounded,
//                                   color: Colors.grey.shade400,
//                                   size: 28,
//                                 ),
//                               ),
//                             )
//                           else
//                             // keep layout stable when icon not shown
//                             const SizedBox(width: 36),
//                         ],
//                       ),

//                       const SizedBox(height: 6),

//                       // Message (animated size)
//                       AnimatedSize(
//                         duration: const Duration(milliseconds: 220),
//                         curve: Curves.easeInOut,
//                         child: ConstrainedBox(
//                           constraints: _expanded
//                               ? const BoxConstraints() // no limit when expanded
//                               : const BoxConstraints(
//                                   maxHeight: 45,
//                                 ), // approximate 2 lines
//                           child: Text(
//                             sanitized,
//                             maxLines: _expanded ? 1000 : 2,
//                             overflow: _expanded
//                                 ? TextOverflow.visible
//                                 : TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // Right: compact actions (mark read / delete) + spacing
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
