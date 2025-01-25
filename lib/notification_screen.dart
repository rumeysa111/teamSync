/*import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message= ModelRoute.of(context)!.settings.argument;
    return Scaffold(
      appBar: AppBar(
        title: const (Text('push notificaitons'),
        ),
        body:Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${message.notification?.title}'),
              Text('${message.notification?.body}'),
              Text('${message.data}'),

            ],
          ),
        )
        
      ),
    );
  }
}
*/