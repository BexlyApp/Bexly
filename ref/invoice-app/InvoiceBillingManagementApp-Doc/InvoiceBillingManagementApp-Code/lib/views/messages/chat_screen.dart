import 'package:flutter/material.dart';

import '../../Widgets/detailstext2.dart';
import '../../Widgets/text11.dart';
import '../../constants/colors.dart';
import '../../widgets/detailstext1.dart';
import 'chatdetailsscreen.dart';



class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.tabColor, // Light blue background
        elevation: 0, // Remove shadow
        toolbarHeight: 40, // Increase AppBar height

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90), // Adjust to fit content
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [

                      SizedBox(
                        width: 6,
                      ),
                      Text1(
                        text1: 'Messages',
                        color: Colors.white,
                        size: 20,
                      ),
                      Spacer(),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          backgroundColor: AppColors.tabColor,
                          child: Center(
                            child: Icon(
                              Icons.notifications,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // My Balance and Top Up section
                const SizedBox(height: 3),

                // Track Number Input
                Card(
                  color: AppColors.buttonColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onTap: (){
                              // Navigator.push(context, MaterialPageRoute(builder: (_)=>const TrackEmpty()));

                            },
                            decoration: const InputDecoration(

                              hintText: 'Search Message',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8,),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                return MessageItem(
                  name: index == 0
                      ? 'Maddy Lin'
                      : index == 1
                      ? 'Sarah Jen'
                      : index == 2
                      ? 'Ron Edward'
                      : index == 3
                      ? 'Alice Adam'
                      : index == 4
                      ? 'Will Smith'
                      : 'Jessica Ben',
                  message: index == 0
                      ? 'Hai Rizal, I\'m on the way...'
                      : index == 1
                      ? 'woohoooo'
                      : index == 2
                      ? 'Haha that\'s terrifying 😂'
                      : index == 3
                      ? 'Wow, this is really epic'
                      : index == 4
                      ? 'Just ideas for next time'
                      : 'How are you?',
                  time: index == 0
                      ? '3:74 Pm'
                      : index == 1
                      ? '6:32 Pm'
                      : index == 2
                      ? '7:22 Pm'
                      : 'Yesterday',
                  profileImage: index == 0
                      ? 'images/c2.png'
                      : index == 1
                      ? 'images/c3.png'
                      : index == 2
                      ? 'images/c4.png'
                      : index == 3
                      ? 'images/c2.png'
                      : index == 4
                      ? 'images/c5.png'
                      : 'images/c2.png',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String profileImage;

  const MessageItem({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>const ChatDetailsScreen()));
      },
      child: Card(

        color: Colors.white,
            elevation: 1,
        margin: const EdgeInsets.only(bottom: 8,left: 8,right: 8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage(profileImage),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text1(
                        text1:   name,
                          size: 17,

                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.tabColor,
                          child: Text11(text2: '2',color: Colors.white,),
                          
                        )

                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text2(
                         text2:  message,

                        ),
                        const Spacer(),
                        Text2(
                          text2:  time,
                        ),

                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}