// Reviews Screen
import 'package:flutter/material.dart';
import 'package:invoiceandbilling/views/reviews/writereview.dart';


import '../../Widgets/customapp_bar.dart';
import '../../widgets/custombtn.dart';
import '../../widgets/detailstext1.dart';

class Reviews extends StatelessWidget {
  const Reviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const CustomAppBar(text: 'Reviews', text1: ''),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    '4.0',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade800,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade800,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade800,
                    ),
                    Icon(
                      Icons.star,
                      color: Colors.yellow.shade800,
                    ),
                    const Icon(
                      Icons.star,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const Center(
                  child: Text(
                    'based on 23 Reviews',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                RatingRow(
                  text: 'Excellent',
                  width: 150,
                  color: Color.fromARGB((0.9 * 255).toInt(), 205, 220, 57),
                ),
                RatingRow(
                  text: 'Good',
                  width: 140,
                  color: Color.fromARGB((0.9 * 255).toInt(), 205, 220, 57),
                ),
                RatingRow(
                  text: 'Average',
                  width: 120,
                  color: Colors.yellow.shade800,
                ),
                const RatingRow(
                  text: 'Below Average',
                  width: 100,
                  color: Colors.purple,
                ),
                const RatingRow(
                  text: 'Poor',
                  width: 50,
                  color: Colors.pink,
                ),
                const SizedBox(height: 10),
                const ReviewsContainer(
                  image: 'images/c3.png',
                  text1: 'James Andre',
                  text2: '4.3',
                  text3: '1 day ago',
                  reviewText:
                  'The  Grocery App has significantly enhanced our grocery shopping experience, providing seamless access to a wide variety of products and reliable delivery options. Its user-friendly interface simplifies the process of finding, ordering, and managing groceries, ensuring a consistently smooth and convenient experience. We highly recommend this app for its effectiveness in fostering a better shopping experience and connection with reliable suppliers.',
                ),
                const ReviewsContainer(
                  image: 'images/c2.png',
                  text1: 'Powell Sumuled',
                  text2: '3.3',
                  text3: '4 day ago',
                  reviewText:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin eu lorem ut quam hendrerit rutrum. Nullam tristique consequat tortor, id sagittis nisl faucibus a. In hac habitasse platea dictumst. Mauris at purus et elit consequat laoreet non ac odio.',
                ),
                const ReviewsContainer(
                  image: 'images/c3.png',
                  text1: 'Hales Andreeed',
                  text2: '5.3',
                  text3: '7 day ago',
                  reviewText:
                  'Integer eu neque a justo sagittis posuere. Morbi nec dolor nec nulla dictum fermentum. Quisque accumsan, sapien id congue lobortis, dui ante sodales quam, eu placerat quam turpis nec magna.',
                ),
                const ReviewsContainer(
                  image: 'images/c4.png',
                  text1: 'Guptel Stin',
                  text2: '2.3',
                  text3: '8 day ago',
                  reviewText:
                  'Suspendisse potenti. Aenean eu nibh nec lectus congue efficitur vel ac lacus. Sed non lobortis erat, et aliquet justo. Nam a suscipit lorem.',
                ),
                const ReviewsContainer(
                  image: 'images/c3.png',
                  text1: 'Andre',
                  text2: '4.3',
                  text3: '6 day ago',
                  reviewText:
                  'Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Quisque euismod convallis leo, non tempor tortor consectetur sed. Curabitur vel vestibulum eros.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: CustomButton(
          text: 'Write A Review',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WriteReviews()),
            );
          },
        ),
      ),
    );
  }
}

class ReviewsContainer extends StatelessWidget {
  final String image;
  final String text1, text2, text3, reviewText;
  const ReviewsContainer({
    super.key,
    required this.image,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.reviewText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: Colors.white,

      child: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    image,
                    width: 35,
                    height: 35,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text1(text1: text1),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade800,
                            size: 15,
                          ),
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade800,
                            size: 15,
                          ),
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade800,
                            size: 15,
                          ),
                          Icon(
                            Icons.star,
                            color: Colors.yellow.shade800,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text1(text1: text2),
                          const Spacer(),
                          Text1(text1: text3),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reviewText,
              style: const TextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingRow extends StatelessWidget {
  final String text;
  final Color color;
  final double width;
  const RatingRow({
    super.key,
    required this.text,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 30),
        Expanded(
          child: Container(
            height: 5,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Row(
              children: [
                Container(
                  height: 5,
                  width: width,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
