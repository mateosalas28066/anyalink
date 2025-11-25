import 'package:flutter/material.dart';

class ScreenMessageDialog extends StatefulWidget {
  final String currentMessage;
  
  const ScreenMessageDialog({
    super.key,
    required this.currentMessage,
  });

  @override
  State<ScreenMessageDialog> createState() => _ScreenMessageDialogState();
}

class _ScreenMessageDialogState extends State<ScreenMessageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentMessage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Screen Message'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter message...',
          border: OutlineInputBorder(),
        ),
        maxLength: 100,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}
