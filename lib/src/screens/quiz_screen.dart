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
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: AppConstants.colorPrimario,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: _confirmarSalir,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.category.nombre,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          // Barra de progreso en el AppBar
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: (_progress.currentIndex + 1) / _progress.total,
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        body: q == null || _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(AppConstants.colorPrimario),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cargando pregunta...',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
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

  /// Layout optimizado para móvil - Compacto y visualmente amigable
  Widget _buildMobileLayout(QuestionModel q, int respondidas, int sinResponder, bool isLastQuestion) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas compactas en chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label: 'Respondidas',
                value: respondidas.toString(),
                color: Colors.green,
              ),
              _buildStatChip(
                icon: Icons.pending_outlined,
                label: 'Pendientes',
                value: sinResponder.toString(),
                color: Colors.orange,
              ),
              _buildStatChip(
                icon: Icons.assignment_outlined,
                label: 'Total',
                value: _progress.total.toString(),
                color: AppConstants.colorPrimario,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Pregunta principal - Diseño limpio y amigable
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppConstants.colorPrimario.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz,
                        color: AppConstants.colorPrimario,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  q.pregunta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Label de opciones con icono
          Row(
            children: [
              Icon(Icons.touch_app, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Selecciona tu respuesta:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Opciones de respuesta
          ..._optionOrder.asMap().entries.map((entry) {
            final position = entry.key;  // Índice visual (0, 1, 2, 3)
            final optIdx = entry.value;  // Índice real en el array original
            final optionText = q.opciones[optIdx];
            final isSelected = _selectedIndex == position;  // ✅ FIX: Comparar con posición visual
            final letra = String.fromCharCode(65 + position);

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _buildOptionTile(
                letra: letra,
                text: optionText,
                isSelected: isSelected,
                onTap: () => setState(() {
                  _selectedIndex = isSelected ? null : position;  // ✅ FIX: Guardar posición visual
                }),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Chip de estadística compacto
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout optimizado para desktop/tablet - Visualmente amigable
  Widget _buildDesktopLayout(
    QuestionModel q,
    int respondidas,
    int sinResponder,
    bool isLastQuestion,
    bool isTablet,
  ) {
    final maxWidth = isTablet ? 900 : 1150;
    
    return Row(
      children: [
        // Panel lateral izquierdo con índice (solo desktop)
        if (!isTablet) _buildQuestionIndex(),

        // Contenido principal
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 40,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas en chips horizontales
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatChipDesktop(
                          icon: Icons.check_circle_outline,
                          label: 'Respondidas',
                          value: respondidas.toString(),
                          color: Colors.green,
                        ),
                        _buildStatChipDesktop(
                          icon: Icons.pending_outlined,
                          label: 'Pendientes',
                          value: sinResponder.toString(),
                          color: Colors.orange,
                        ),
                        _buildStatChipDesktop(
                          icon: Icons.assignment_outlined,
                          label: 'Total',
                          value: _progress.total.toString(),
                          color: AppConstants.colorPrimario,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Pregunta principal - Diseño elegante
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isTablet ? 24 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppConstants.colorPrimario.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  color: AppConstants.colorPrimario,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pregunta ${_progress.currentIndex + 1} de ${_progress.total}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            q.pregunta,
                            style: TextStyle(
                              fontSize: isTablet ? 19 : 21,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Label de opciones
                    Row(
                      children: [
                        Icon(Icons.touch_app, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Selecciona tu respuesta:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Opciones en grid (2 columnas)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _optionOrder.asMap().entries.map((entry) {
                        final position = entry.key;  // Índice visual (0, 1, 2, 3)
                        final optIdx = entry.value;  // Índice real en el array original
                        final optionText = q.opciones[optIdx];
                        final isSelected = _selectedIndex == position;  // ✅ FIX: Comparar con posición visual
                        final letra = String.fromCharCode(65 + position);

                        return SizedBox(
                          width: (maxWidth - 48) / 2,
                          child: _buildOptionCard(
                            letra: letra,
                            text: optionText,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedIndex = isSelected ? null : position;  // ✅ FIX: Guardar posición visual
                            }),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Chip de estadística para desktop
  Widget _buildStatChipDesktop({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }





  /// Opción como tarjeta (para desktop/tablet) - Diseño elegante y amigable
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? AppConstants.colorPrimario 
                  : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? AppConstants.colorPrimario.withOpacity(0.05)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? AppConstants.colorPrimario.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: isSelected ? 12 : 6,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Letra de opción - círculo con gradiente
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            AppConstants.colorPrimario,
                            AppConstants.colorPrimario.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? AppConstants.colorPrimario 
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppConstants.colorPrimario.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    letra,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Texto de opción
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Indicador de selección animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 28 : 0,
                child: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: AppConstants.colorPrimario,
                        size: 28,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opción como tile (para móvil) - Diseño amigable y compacto
  Widget _buildOptionTile({
    required String letra,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? AppConstants.colorPrimario 
                : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppConstants.colorPrimario.withOpacity(0.05)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppConstants.colorPrimario.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 10 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Letra de opción - círculo más grande y amigable
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(
                        colors: [
                          AppConstants.colorPrimario,
                          AppConstants.colorPrimario.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? AppConstants.colorPrimario 
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppConstants.colorPrimario.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  letra,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Texto de opción
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Indicador de selección animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 24 : 0,
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: AppConstants.colorPrimario,
                      size: 24,
                    )
                  : null,
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: const Text(
              'Preguntas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                child: Wrap(
                  direction: Axis.vertical,
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
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
                          width: 48,
                          height: 48,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isCurrent ? Colors.white : Colors.black87,
                                fontSize: 13,
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
          ),
        ],
      ),
    );
  }





  /// Barra de navegación inferior - Compacta y adaptable
  Widget _buildBottomNavigationBar(bool isLastQuestion) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            // Botón anterior compacto (solo si no es la primera pregunta)
            if (_progress.currentIndex > 0) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _progress = _progress.copyWith(
                                currentIndex: _progress.currentIndex - 1,
                              );
                              _loadCurrent();
                            });
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            
            // Botón siguiente/finalizar adaptable
            if (isMobile)
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedIndex == null || _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: AppConstants.colorPrimario,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: _selectedIndex != null ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (_selectedIndex == null) ...[
                        const Icon(Icons.touch_app, size: 16),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _selectedIndex == null
                            ? 'Selecciona una respuesta'
                            : isLastQuestion
                                ? 'Finalizar'
                                : 'Siguiente',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedIndex != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: _selectedIndex == null || _isLoading ? null : _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  backgroundColor: AppConstants.colorPrimario,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: _selectedIndex != null ? 2 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIndex == null) ...[
                      const Icon(Icons.touch_app, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _selectedIndex == null
                          ? 'Selecciona una respuesta'
                          : isLastQuestion
                              ? 'Finalizar'
                              : 'Siguiente',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (_selectedIndex != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
