import 'package:flutter/material.dart';
import 'dart:async';
import '../config/app_constants.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/quiz_progress_model.dart';
import '../services/quiz_service.dart';
import 'results_screen.dart';

/// Pantalla que ejecuta el test de una categoría
/// - Muestra preguntas una por una
/// - Randomiza preguntas y opciones
/// - Guarda progreso automáticamente
/// - Permite pausar/reanudar sin reiniciar
class QuizScreen extends StatefulWidget {
  final CategoryModel category;
  final QuizProgressModel initialProgress;
  const QuizScreen({super.key, required this.category, required this.initialProgress});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizService = QuizService();

  late QuizProgressModel _progress;
  QuestionModel? _currentQuestion;
  List<int> _optionOrder = [0, 1, 2, 3];
  int? _selectedIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress;
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      print('🔄 _loadCurrent() iniciado para categoryId=${_progress.categoryId}, index=${_progress.currentIndex}');
      
      if (!mounted) {
        print('❌ Widget no está montado');
        return;
      }
      
      setState(() => _isLoading = true);
      print('⏳ Loading iniciado');
      
      try {
        print('📋 Llamando a getCurrentQuestion() con timeout de 10s...');
        final q = await _quizService.getCurrentQuestion(_progress)
            .timeout(const Duration(seconds: 10), onTimeout: () {
              print('⏱️ TIMEOUT en getCurrentQuestion()');
              return null;
            });
        print('✅ getCurrentQuestion() retornó: ${q != null ? 'Pregunta cargada' : 'null'}');
        
        if (!mounted) {
          print('❌ Widget se desmontó durante getCurrentQuestion()');
          return;
        }
        
        // ✨ MEJORA: Obtener orden de opciones guardado (aleatoriedad determinística)
        print('📋 Llamando a getOptionOrderForCurrentQuestion()...');
        _optionOrder = await _quizService.getOptionOrderForCurrentQuestion(_progress)
            .timeout(const Duration(seconds: 5), onTimeout: () {
              print('⏱️ TIMEOUT en getOptionOrderForCurrentQuestion()');
              return [0, 1, 2, 3];
            });
        print('✅ getOptionOrderForCurrentQuestion() retornó: $_optionOrder');
        
        if (!mounted) {
          print('❌ Widget se desmontó durante getOptionOrderForCurrentQuestion()');
          return;
        }
        
        print('🎨 Actualizando setState()...');
        setState(() {
          _currentQuestion = q;
          _selectedIndex = null;
          _isLoading = false;
        });
        print('✅ setState() completado');
      } on TimeoutException catch (e) {
        print('❌ TimeoutException en _loadCurrent(): $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timeout cargando pregunta'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('❌ Error en _loadCurrent(): $e');
      print('   Stack trace: ${StackTrace.current}');
      
      if (!mounted) {
        print('❌ Widget no está montado, no puedo mostrar error');
        return;
      }
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _next() async {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una respuesta')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      _progress = await _quizService.answerAndNext(_progress, _selectedIndex!);

      final q = await _quizService.getCurrentQuestion(_progress);
      if (!mounted) return;

      if (q == null) {
        // Finalizó el test
        final score = await _quizService.finishAndScore(widget.category.id);
        if (!mounted) return;

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              category: widget.category,
              total: widget.initialProgress.total,
              correct: score,
            ),
          ),
        );
      } else {
        // Siguiente pregunta
        _optionOrder = await _quizService.getOptionOrderForCurrentQuestion(_progress);
        
        setState(() {
          _currentQuestion = q;
          _selectedIndex = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmarSalir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonar Test'),
        content: const Text(
          'Tu progreso será guardado. Podrás continuar después desde donde lo dejaste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final isLastQuestion = _progress.currentIndex + 1 == _progress.total;
    final respondidas = _progress.respuestas.where((r) => r != null).length;
    final sinResponder = _progress.total - respondidas;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return WillPopScope(
      onWillPop: () async {
        _confirmarSalir();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppConstants.colorPrimario,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _confirmarSalir,
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.category.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Indicador mejorado en el AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: ClipRRect(
              child: LinearProgressIndicator(
                value: (_progress.currentIndex + 1) / _progress.total,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),
          ),
        ),
        body: q == null || _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando pregunta...'),
                  ],
                ),
              )
            : isMobile
                ? _buildMobileLayout(q, respondidas, sinResponder, isLastQuestion)
                : _buildDesktopLayout(q, respondidas, sinResponder, isLastQuestion, isTablet),
        bottomNavigationBar: q == null || _isLoading
            ? null
            : _buildBottomNavigationBar(isLastQuestion),
      ),
    );
  }

  /// Layout optimizado para móvil
  Widget _buildMobileLayout(QuestionModel q, int respondidas, int sinResponder, bool isLastQuestion) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barras de progreso compactas
          _buildCompactProgressBars(respondidas, sinResponder),
          const SizedBox(height: 24),

          // Pregunta principal - Mejorada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta ${_progress.currentIndex + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.colorPrimario,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.pregunta,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Opciones de respuesta
          Text(
            'Selecciona la respuesta correcta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),

          ..._optionOrder.asMap().entries.map((entry) {
            final position = entry.key;
            final optIdx = entry.value;
            final optionText = q.opciones[optIdx];
            final isSelected = _selectedIndex == optIdx;
            final letra = String.fromCharCode(65 + position);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOptionTile(
                letra: letra,
                text: optionText,
                isSelected: isSelected,
                onTap: () => setState(() {
                  // Toggle: si ya estaba seleccionada, deseleccionar
                  _selectedIndex = isSelected ? null : optIdx;
                }),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Layout optimizado para desktop/tablet
  Widget _buildDesktopLayout(
    QuestionModel q,
    int respondidas,
    int sinResponder,
    bool isLastQuestion,
    bool isTablet,
  ) {
    final maxWidth = isTablet ? 800 : 1000;
    
    return Row(
      children: [
        // Panel lateral izquierdo con índice (solo desktop)
        if (!isTablet) _buildQuestionIndex(),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 28 : 40,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barras de progreso mejoradas
                    _buildProgressBars(respondidas, sinResponder),
                    const SizedBox(height: 32),

                    // Pregunta principal con estilo mejorado
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.colorPrimario,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            q.pregunta,
                            style: TextStyle(
                              fontSize: isTablet ? 19 : 22,
                              fontWeight: FontWeight.w800,
                              height: 1.6,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Label de opciones
                    Text(
                      'Selecciona la respuesta correcta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opciones en grid (2 columnas en desktop/tablet)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _optionOrder.asMap().entries.map((entry) {
                        final position = entry.key;
                        final optIdx = entry.value;
                        final optionText = q.opciones[optIdx];
                        final isSelected = _selectedIndex == optIdx;
                        final letra = String.fromCharCode(65 + position);

                        return SizedBox(
                          width: isTablet
                              ? (maxWidth - 44) / 2
                              : (maxWidth - 44) / 2,
                          child: _buildOptionCard(
                            letra: letra,
                            text: optionText,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              // Toggle: si ya estaba seleccionada, deseleccionar
                              _selectedIndex = isSelected ? null : optIdx;
                            }),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Barras de progreso para desktop
  Widget _buildProgressBars(int respondidas, int sinResponder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Respondidas',
                respondidas.toString(),
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Sin responder',
                sinResponder.toString(),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total',
                _progress.total.toString(),
                AppConstants.colorPrimario,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Barras de progreso compactas para móvil
  Widget _buildCompactProgressBars(int respondidas, int sinResponder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactStatCard(
                'Respondidas',
                respondidas.toString(),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                'Sin responder',
                sinResponder.toString(),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactStatCard(
                'Total',
                _progress.total.toString(),
                AppConstants.colorPrimario,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Opción como tarjeta (para desktop/tablet)
  Widget _buildOptionCard({
    required String letra,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? AppConstants.colorPrimario 
                  : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? AppConstants.colorPrimario.withOpacity(0.08)
                : Colors.white,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppConstants.colorPrimario.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Letra de opción
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppConstants.colorPrimario 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected 
                        ? AppConstants.colorPrimario 
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    letra,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Texto de opción
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opción como tile (para móvil)
  Widget _buildOptionTile({
    required String letra,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? AppConstants.colorPrimario 
                : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppConstants.colorPrimario.withOpacity(0.08)
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppConstants.colorPrimario.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Letra de opción
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppConstants.colorPrimario 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected 
                      ? AppConstants.colorPrimario 
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  letra,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Texto de opción
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el panel lateral de índice (solo desktop)
  Widget _buildQuestionIndex() {
    return Container(
      width: 75,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: const Text(
              'Preguntas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                direction: Axis.vertical,
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_progress.total, (index) {
                  final isAnswered = _progress.respuestas[index] != null;
                  final isCurrent = index == _progress.currentIndex;

                  return GestureDetector(
                    onTap: () {
                      if (isAnswered || isCurrent) {
                        setState(() {
                          _progress = _progress.copyWith(currentIndex: index);
                          _loadCurrent();
                        });
                      }
                    },
                    child: Tooltip(
                      message: isCurrent
                          ? 'Pregunta actual'
                          : isAnswered
                              ? 'Respondida'
                              : 'No respondida',
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppConstants.colorPrimario
                              : isAnswered
                                  ? Colors.green.shade50
                                  : Colors.white,
                          border: Border.all(
                            color: isCurrent
                                ? AppConstants.colorPrimario
                                : isAnswered
                                    ? Colors.green.shade400
                                    : Colors.grey.shade300,
                            width: isCurrent ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isCurrent ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para tarjeta de estadísticas (desktop)
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget para tarjeta de estadísticas compacta (móvil)
  Widget _buildCompactStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Barra de navegación inferior mejorada
  Widget _buildBottomNavigationBar(bool isLastQuestion) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 20,
        isMobile ? 10 : 14,
        isMobile ? 14 : 20,
        isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedIndex == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 17),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Selecciona una respuesta para continuar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedIndex == null) const SizedBox(height: 12),
          Row(
            children: [
              // Botón anterior (si no es la primera pregunta)
              if (_progress.currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                    label: Text(
                      isMobile ? 'Anterior' : 'Anterior',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _progress = _progress.copyWith(
                                currentIndex: _progress.currentIndex - 1,
                              );
                              _loadCurrent();
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 11,
                      ),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (_progress.currentIndex > 0) const SizedBox(width: 10),
              // Botón siguiente/finalizar
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                    size: 17,
                  ),
                  label: Text(
                    isLastQuestion 
                        ? (isMobile ? 'Finalizar' : 'Finalizar')
                        : (isMobile ? 'Siguiente' : 'Siguiente'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: _selectedIndex == null || _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 10 : 11,
                    ),
                    backgroundColor: AppConstants.colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
