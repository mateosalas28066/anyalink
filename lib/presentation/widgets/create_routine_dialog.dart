import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routines_providers.dart';
import '../providers/device_list_providers.dart';
import '../../infrastructure/supabase/device_repo.dart';

class CreateRoutineDialog extends ConsumerStatefulWidget {
  const CreateRoutineDialog({super.key});

  @override
  ConsumerState<CreateRoutineDialog> createState() => _CreateRoutineDialogState();
}

class _CreateRoutineDialogState extends ConsumerState<CreateRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DeviceEntity? _selectedDevice;
  String _actionType = 'set_state';
  String _actionPayload = 'true'; // Default to ON
  int _intervalSeconds = 10;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesListProvider);

    return AlertDialog(
      title: const Text('Create Routine'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Device Selector
              devicesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error loading devices: $e'),
                data: (devices) {
                  if (devices.isEmpty) return const Text('No devices available');
                  
                  return DropdownButtonFormField<DeviceEntity>(
                    value: _selectedDevice,
                    decoration: const InputDecoration(labelText: 'Device'),
                    items: devices.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d.alias),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDevice = val;
                        // Reset payload based on device type if needed
                        if (val?.type == 'dispenser') {
                           _actionPayload = 'true';
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Select a device' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Action Type (Simplified for Demo)
              DropdownButtonFormField<String>(
                value: _actionType,
                decoration: const InputDecoration(labelText: 'Action Type'),
                items: const [
                  DropdownMenuItem(value: 'set_state', child: Text('Set State (ON/OFF)')),
                  DropdownMenuItem(value: 'set_message', child: Text('Set Message (LCD)')),
                ],
                onChanged: (val) => setState(() => _actionType = val!),
              ),
              const SizedBox(height: 16),

              // Action Payload
              if (_actionType == 'set_state')
                DropdownButtonFormField<String>(
                  value: _actionPayload,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: const [
                    DropdownMenuItem(value: 'true', child: Text('ON')),
                    DropdownMenuItem(value: 'false', child: Text('OFF')),
                  ],
                  onChanged: (val) => setState(() => _actionPayload = val!),
                )
              else
                TextFormField(
                  initialValue: _actionPayload,
                  decoration: const InputDecoration(labelText: 'Message Text'),
                  onChanged: (val) => _actionPayload = val,
                  validator: (val) => val == null || val.isEmpty ? 'Enter a message' : null,
                ),
              const SizedBox(height: 16),

              // Interval Slider
              Text('Interval: $_intervalSeconds seconds'),
              Slider(
                value: _intervalSeconds.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$_intervalSeconds s',
                onChanged: (val) => setState(() => _intervalSeconds = val.toInt()),
              ),
              const Text(
                'Note: Routine will expire automatically after 1 hour.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDevice == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(routinesRepoProvider).createRoutine(
        deviceId: _selectedDevice!.id,
        actionType: _actionType,
        actionPayload: _actionPayload,
        intervalSeconds: _intervalSeconds,
      );
      
      ref.invalidate(userRoutinesProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine created successfully')),
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
}
