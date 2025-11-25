import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../infrastructure/supabase/request_repo.dart';

class DeviceRequestDialog extends ConsumerStatefulWidget {
  const DeviceRequestDialog({super.key});

  @override
  ConsumerState<DeviceRequestDialog> createState() => _DeviceRequestDialogState();
}

class _DeviceRequestDialogState extends ConsumerState<DeviceRequestDialog> {
  final _commentController = TextEditingController();
  String? _selectedDeviceId;
  List<Map<String, dynamic>> _deviceOptions = [];
  bool _isLoading = false;
  bool _isFetchingOptions = true;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final client = Supabase.instance.client;
      final repo = RequestRepository(client);
      final options = await repo.getDeviceOptions();
      if (mounted) {
        setState(() {
          _deviceOptions = options;
          if (options.isNotEmpty) {
            _selectedDeviceId = options.first['id'] as String;
          }
          _isFetchingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingOptions = false);
        // Fallback or error handling
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedDeviceId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final repo = RequestRepository(client);

      // Find selected device to get type/alias for desiredType (optional)
      final selectedDevice = _deviceOptions.firstWhere(
        (d) => d['id'] == _selectedDeviceId,
        orElse: () => {},
      );

      await repo.createRequest(
        userId: userId,
        desiredType: selectedDevice['alias'] as String?, // Use alias as type description
        targetDeviceId: _selectedDeviceId,
        comment: _commentController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Device Access'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the device you want to access:'),
            const SizedBox(height: 12),
            if (_isFetchingOptions)
              const Center(child: CircularProgressIndicator())
            else if (_deviceOptions.isEmpty)
               const Text('No devices available to request.', style: TextStyle(color: Colors.red))
            else
              DropdownButtonFormField<String>(
                value: _selectedDeviceId,
                items: _deviceOptions.map((d) {
                  return DropdownMenuItem<String>(
                    value: d['id'] as String,
                    child: Text(d['alias'] as String? ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDeviceId = val),
                decoration: const InputDecoration(
                  labelText: 'Device',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (Optional)',
                hintText: 'Why do you need access?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || _selectedDeviceId == null) ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}
