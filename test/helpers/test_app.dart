import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anyalink_1/core/env.dart';
import 'package:anyalink_1/infrastructure/supabase/device_repo.dart';
import 'package:anyalink_1/main.dart';
import 'package:anyalink_1/presentation/providers/device_providers.dart';

class _FakeDeviceRepo implements DeviceRepository {
  _FakeDeviceRepo({
    required bool initialState,
    bool online = false,
    String type = 'mock',
    String? alias,
  })  : _state = initialState,
        _online = online,
        _type = type,
        _alias = alias {
    _stateController = StreamController<bool>.broadcast(
      onListen: () => _stateController.add(_state),
    );
    _listController = StreamController<List<DeviceEntity>>.broadcast(
      onListen: () => _listController.add([_deviceModel()]),
    );
    _metricsController = StreamController<DeviceMetrics?>.broadcast(
      onListen: () => _metricsController.add(_metricsValue),
    );
  }

  bool _state;
  final bool _online;
  final String _type;
  final String? _alias;

  late final StreamController<bool> _stateController;
  late final StreamController<List<DeviceEntity>> _listController;
  late final StreamController<DeviceMetrics?> _metricsController;

  DeviceMetrics? _metricsValue;

  // Tracking de llamadas a sendCommand
  final List<Map<String, dynamic>> sentCommands = [];

  DeviceEntity _deviceModel() => DeviceEntity(
        id: '1',
        alias: _alias ??
            (_type == 'feeder' ? Env.dispenserAlias : Env.lightAlias),
        state: _state,
        type: _type,
        online: _online,
      );

  void _emitAll() {
    final device = _deviceModel();
    _stateController.add(device.state);
    _listController.add([device]);
  }

  void emitMetrics(DeviceMetrics metrics) {
    _metricsValue = metrics;
    _metricsController.add(metrics);
  }

  @override
  Future<DeviceEntity?> getByAlias(String alias) async => _deviceModel();

  @override
  Future<List<DeviceEntity>> getAll() async => [_deviceModel()];

  @override
  Future<void> setStateByAlias(String alias, bool newState) async {
    _state = newState;
    _emitAll();
  }

  @override
  Future<void> setStateById(String id, bool newState) async {
    await setStateByAlias(_alias ?? Env.lightAlias, newState);
  }

  @override
  Stream<bool> watchStateByAlias(String alias) => _stateController.stream;

  @override
  Stream<List<DeviceEntity>> watchAll() => _listController.stream;

  @override
  Future<void> sendCommand(
    String deviceId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    sentCommands.add({
      'deviceId': deviceId,
      'action': action,
      'payload': payload,
    });
  }

  @override
  Stream<DeviceMetrics?> watchMetrics(String deviceId) =>
      _metricsController.stream;

  void dispose() {
    _stateController.close();
    _listController.close();
    _metricsController.close();
  }
}

ProviderScope buildTestApp({bool initialState = false}) {
  return ProviderScope(
    overrides: [
      deviceRepoProvider.overrideWith((ref) {
        final fake = _FakeDeviceRepo(initialState: initialState);
        ref.onDispose(fake.dispose);
        return fake;
      }),
    ],
    child: const AnyaLinkApp(),
  );
}

({ProviderScope app, _FakeDeviceRepo repo}) buildFeederTestApp({
  bool initialState = false,
  bool online = true,
}) {
  final fake = _FakeDeviceRepo(
    initialState: initialState,
    online: online,
    type: 'feeder',
  );
  final app = ProviderScope(
    overrides: [
      deviceRepoProvider.overrideWith((ref) {
        ref.onDispose(fake.dispose);
        return fake;
      }),
    ],
    child: const AnyaLinkApp(),
  );
  return (app: app, repo: fake);
}
