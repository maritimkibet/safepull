import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Dummy user data
  final String userName = "John Doe";
  final String email = "john.doe@example.com";
  final String phone = "+254 700 000000";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 60),
            ),
            SizedBox(height: 20),
            Text(userName, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Text(email, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: 8),
            Text(phone, style: Theme.of(context).textTheme.bodyMedium),
            Spacer(),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () {
                // TODO: Implement logout logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout pressed')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

