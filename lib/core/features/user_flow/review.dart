// import 'package:flutter/material.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// class ReviewPage extends StatefulWidget {
//   const ReviewPage({super.key});

//   @override
//   State<ReviewPage> createState() => _ReviewPageState();
// }

// class _ReviewPageState extends State<ReviewPage> {
//   double rating = 0;
//   final commentController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('レビューを投稿'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("星評価（1〜5）"),
//             const SizedBox(height: 10),

//             // ⭐ 星評価
//             RatingBar.builder(
//               minRating: 1,
//               itemSize: 40,
//               itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
//               onRatingUpdate: (value) {
//                 setState(() {
//                   rating = value;
//                 });
//               },
//             ),

//             const SizedBox(height: 20),
//             const Text("コメント"),

//             // 📝 コメント入力
//             TextField(
//               controller: commentController,
//               maxLines: 4,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 hintText: "コメントを書いてください",
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📤 送信ボタン
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   if (rating == 0 || commentController.text.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("星評価とコメントを入力してください")),
//                     );
//                     return;
//                   }

//                   // 仮処理：実際はDBへ送信など
//                   print("評価: $rating");
//                   print("コメント: ${commentController.text}");

//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("レビューを投稿しました！")),
//                   );
//                 },
//                 child: const Text("投稿する"),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
