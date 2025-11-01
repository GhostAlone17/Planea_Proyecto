import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Widget que indica el estado de conectividad (online/offline)
/// Se muestra en el AppBar como un icono:
/// - Verde (online)
/// - Gris (offline)
/// - Naranja (conectando)
class OfflineIndicatorWidget extends StatefulWidget {
  final double size;
  final bool showLabel;

  const OfflineIndicatorWidget({
    super.key,
    this.size = 24,
    this.showLabel = false,
  });

  @override
  State<OfflineIndicatorWidget> createState() => _OfflineIndicatorWidgetState();
}

class _OfflineIndicatorWidgetState extends State<OfflineIndicatorWidget> {
  late Stream<ConnectivityResult> _connectivityStream;
  late ConnectivityResult _currentStatus = ConnectivityResult.other;
  late bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _currentStatus = ConnectivityResult.other;
      _isOnline = true;
    }
  }

  void _updateStatus(dynamic result) {
    try {
      if (result is List<ConnectivityResult>) {
        _currentStatus = result.isNotEmpty ? result.first : ConnectivityResult.none;
      } else if (result is ConnectivityResult) {
        _currentStatus = result;
      }
      
      _isOnline = _currentStatus != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error updating status: $e');
      _isOnline = true; // Asumir online por defecto
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data;
          _updateStatus(result);
        }

        final isOnline = _isOnline;

        return Tooltip(
          message: isOnline ? 'Conectado' : 'Sin conexión',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.grey,
                  size: widget.size,
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget que muestra una notificación flotante de sincronización
class SyncNotificationWidget extends StatefulWidget {
  final Stream<SyncEvent> syncStream;

  const SyncNotificationWidget({
    super.key,
    required this.syncStream,
  });

  @override
  State<SyncNotificationWidget> createState() => _SyncNotificationWidgetState();
}

class _SyncNotificationWidgetState extends State<SyncNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  SyncEvent? _currentEvent;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showNotification(SyncEvent event) {
    setState(() {
      _currentEvent = event;
      _isVisible = true;
    });

    _animationController.forward();

    // Auto-hide after 3 seconds for success
    if (event.status == 'success') {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _hideNotification();
      });
    }
  }

  void _hideNotification() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
          _currentEvent = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncEvent>(
      stream: widget.syncStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _showNotification(snapshot.data!);
        }

        if (!_isVisible || _currentEvent == null) {
          return const SizedBox.shrink();
        }

        return ScaleTransition(
          scale: _animationController,
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _getColorForStatus(_currentEvent!.status),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconForStatus(_currentEvent!.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitleForStatus(_currentEvent!.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentEvent!.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _currentEvent!.message!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_currentEvent!.status != 'syncing') ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _hideNotification,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'syncing':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildIconForStatus(String status) {
    switch (status) {
      case 'syncing':
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        );
      case 'success':
        return const Icon(
          Icons.check_circle,
          color: Colors.white,
        );
      case 'error':
        return const Icon(
          Icons.error_outline,
          color: Colors.white,
        );
      default:
        return const Icon(
          Icons.info,
          color: Colors.white,
        );
    }
  }

  String _getTitleForStatus(String status) {
    switch (status) {
      case 'syncing':
        return 'Sincronizando...';
      case 'success':
        return 'Sincronizado';
      case 'error':
        return 'Error de sincronización';
      default:
        return 'Actualización';
    }
  }
}

/// Evento de sincronización
class SyncEvent {
  final String status; // 'syncing', 'success', 'error'
  final String? message;
  final DateTime timestamp;

  SyncEvent({
    required this.status,
    this.message,
    required this.timestamp,
  });
}
