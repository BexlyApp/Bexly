import 'package:flutter/material.dart';

import '../../constants/colors.dart';


class ChatDetailsScreen extends StatelessWidget {
  const ChatDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to previous screen
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                  'images/c2.png'), // Assuming image is in assets folder
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maddy Lin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true, // Scroll to the bottom by default
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Yesterday',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message:
                      'Hai Rizal, I\'m on the way to your home, Please wait a moment. Thanks!',
                      isSent: false,
                      time: '4:26 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message: 'Thank You! I\'ll be waiting for that',
                      isSent: true,
                      time: '5:22 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message:
                      'Hai Rizal, I\'m on the way to your home, Please wait a moment. Thanks!',
                      isSent: false,
                      time: '6:28 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message: 'Okay, I\'m here. Where should I drop it?',
                      isSent: true,
                      time: '7:15 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message:
                      'Just bring it to the living room. I\'ll leave the door open',
                      isSent: false,
                      time: '7:20 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message: 'Sure. I\'ll be there in a minute',
                      isSent: true,
                      time: '7:22 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message: 'Great. Thanks again!',
                      isSent: false,
                      time: '7:25 Am',
                    ),
                    const SizedBox(height: 8),
                    const MessageBubble(
                      message:
                      'No problem! Let me know if you need anything else',
                      isSent: true,
                      time: '7:26 Am',
                    ),
                    // Add more messages here as needed
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mic,
                  color: Colors.grey,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.emoji_emotions,
                    color: Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.send,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final String time;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSent ? Colors.white : AppColors.tabColor,
          borderRadius: BorderRadius.only(
            topLeft: isSent ? const Radius.circular(0) : const Radius.circular(10),
            topRight: isSent ? const Radius.circular(10) : const Radius.circular(0),
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isSent ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isSent ? Colors.black : Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}