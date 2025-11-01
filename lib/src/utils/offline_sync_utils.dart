import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Gestiona la sincronización offline y el estado de conectividad
class OfflineSyncUtils {
  static final OfflineSyncUtils _instance = OfflineSyncUtils._internal();
  factory OfflineSyncUtils() => _instance;
  OfflineSyncUtils._internal();

  final _connectivity = Connectivity();
  final _syncQueue = <SyncOperation>[];
  StreamSubscription? _connectionSubscription;
  bool _isOnline = true;
  
  // Listeners para cambios de estado
  final _onlineStatusChangeStream = StreamController<bool>.broadcast();

  /// Stream de cambios de conectividad
  Stream<bool> get onlineStatusChanges => _onlineStatusChangeStream.stream;

  /// Estado actual de conectividad
  bool get isOnline => _isOnline;

  /// Cantidad de operaciones en cola
  int get queuedOperations => _syncQueue.length;

  /// Inicializa la monitorización de conectividad
  Future<void> initialize() async {
    try {
      // Determinar estado inicial
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;

      // Escuchar cambios de conectividad
      _connectionSubscription = _connectivity.onConnectivityChanged.listen((result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;

        // Notificar cambios
        if (wasOnline != _isOnline) {
          _onlineStatusChangeStream.add(_isOnline);

          // Si volvió online, procesar cola
          if (_isOnline) {
            _processSyncQueue();
          }
        }
      });
    } catch (e) {
      print('⚠️ Error inicializando connectividad: $e');
      // Por defecto asumir online
      _isOnline = true;
    }
  }

  /// Ejecuta una operación con reintentos automáticos y backoff exponencial
  /// Retorna Future que se resuelve cuando la operación es exitosa
  /// o max_retries ha sido alcanzado
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        // Verificar conectividad
        if (!_isOnline) {
          throw OfflineException('Sin conexión a internet');
        }

        // Intentar operación
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          // Si fue offline, encolar operación
          if (e is OfflineException || !_isOnline) {
            _queueOperation(operation);
            throw OfflineException('Operación encolada para sincronización posterior');
          }
          rethrow;
        }

        print('⚠️ Intento $attempt falló, reintentando en ${delay.inMilliseconds}ms: $e');

        // Esperar antes de reintentar
        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }

    throw Exception('Operación falló después de $maxRetries intentos');
  }

  /// Encola una operación para sincronización posterior
  void _queueOperation<T>(Future<T> Function() operation) {
    final syncOp = SyncOperation(
      operation: operation,
      timestamp: DateTime.now(),
      retries: 0,
    );
    _syncQueue.add(syncOp);
    print('📋 Operación encolada. Cola: ${_syncQueue.length} operaciones');
  }

  /// Procesa la cola de operaciones pendientes
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || !_isOnline) return;

    print('🔄 Procesando ${_syncQueue.length} operaciones en cola...');

    final processed = <int>[];

    for (int i = 0; i < _syncQueue.length; i++) {
      final syncOp = _syncQueue[i];

      try {
        await executeWithRetry(
          operation: syncOp.operation,
          maxRetries: 3,
        );
        processed.add(i);
        print('✅ Operación $i sincronizada exitosamente');
      } catch (e) {
        syncOp.retries++;

        // Si superó reintentos, remover
        if (syncOp.retries >= 5) {
          processed.add(i);
          print('❌ Operación $i descartada después de 5 reintentos: $e');
        } else {
          print('⚠️ Operación $i fallió (intento ${syncOp.retries}), se reintentará');
        }
      }
    }

    // Remover operaciones procesadas (en orden inverso para no afectar índices)
    for (final index in processed.reversed) {
      _syncQueue.removeAt(index);
    }

    if (_syncQueue.isNotEmpty) {
      print('📋 ${_syncQueue.length} operaciones aún pendientes');
    } else {
      print('✅ Cola de sincronización vacía');
    }
  }

  /// Limpia recursos
  void dispose() {
    _connectionSubscription?.cancel();
    _onlineStatusChangeStream.close();
  }
}

/// Excepción específica para fallos de conectividad
class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);

  @override
  String toString() => message;
}

/// Representa una operación que debe sincronizarse
class SyncOperation {
  final Future Function() operation;
  final DateTime timestamp;
  int retries;

  SyncOperation({
    required this.operation,
    required this.timestamp,
    required this.retries,
  });
}
