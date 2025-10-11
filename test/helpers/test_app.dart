import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anyalink_1/core/env.dart';
import 'package:anyalink_1/infrastructure/supabase/device_repo.dart';
import 'package:anyalink_1/main.dart';
import 'package:anyalink_1/presentation/providers/device_providers.dart';

class _FakeDeviceRepo implements DeviceRepository {
  _FakeDeviceRepo({required bool initialState})
      : _state = initialState {
    _stateController = StreamController<bool>.broadcast(
      onListen: () => _stateController.add(_state),
    );
    _listController = StreamController<List<DeviceEntity>>.broadcast(
      onListen: () => _listController.add([_deviceModel()]),
    );
  }

  bool _state;
  late final StreamController<bool> _stateController;
  late final StreamController<List<DeviceEntity>> _listController;

  DeviceEntity _deviceModel() => DeviceEntity(
        id: '1',
        alias: Env.lightAlias,
        state: _state,
        type: 'mock',
      );

  void _emitAll() {
    final device = _deviceModel();
    _stateController.add(device.state);
    _listController.add([device]);
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
    await setStateByAlias(Env.lightAlias, newState);
  }

  @override
  Stream<bool> watchStateByAlias(String alias) => _stateController.stream;

  @override
  Stream<List<DeviceEntity>> watchAll() => _listController.stream;

  void dispose() {
    _stateController.close();
    _listController.close();
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
