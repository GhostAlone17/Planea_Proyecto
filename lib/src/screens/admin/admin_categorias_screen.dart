import 'package:flutter/material.dart';
import '../../models/category_model_v2.dart';
import '../../services/admin_service.dart';

/// Pantalla para gestionar categorías de reactivos
class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  late List<CategoryModelV2> _categorias;
  late AdminService _adminService;
  late Map<String, int> _reactivosPorCategoria;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService();
    _categorias = CategoryModelV2.categoriasDefault();
    _reactivosPorCategoria = {};
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final stats = await _adminService.obtenerReactivosPorCategoria();
    setState(() {
      _reactivosPorCategoria = stats;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isWeb = screenWidth >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Categorías',
          style: TextStyle(fontSize: isMobile ? 16 : 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: isMobile ? 20 : 28,
                    color: Colors.purple,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categorías PLANEA',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : (isTablet ? 18 : 22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${_categorias.length} categorías',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 20),

              // Categorías en formato de lista compacta O grid según pantalla
              _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : isWeb
                      ? _buildGridLayout(isWeb, isTablet, isMobile)
                      : _buildListLayout(isMobile),

              SizedBox(height: isMobile ? 16 : 24),

              // Info card compacta
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: Text(
                              'Información PLANEA',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        'Las 6 categorías de matemáticas del PLANEA son predefinidas y no pueden ser modificadas. Cada categoría contiene reactivos específicos que evalúan habilidades diferentes.',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          color: Colors.blue.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout de grid para pantallas grandes (web)
  Widget _buildGridLayout(bool isWeb, bool isTablet, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWeb ? 3 : (isTablet ? 2 : 1),
        childAspectRatio: isWeb ? 1.0 : (isTablet ? 1.2 : 1.8),
        crossAxisSpacing: isWeb ? 20 : 12,
        mainAxisSpacing: isWeb ? 20 : 12,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final categoria = _categorias[index];
        return isWeb
            ? _buildCategoryCardGrande(categoria)
            : _buildCategoryCardCompacto(categoria);
      },
    );
  }

  /// Layout de lista para pantallas pequeñas (mobile/tablet)
  Widget _buildListLayout(bool isMobile) {
    return Column(
      children: _categorias.map((categoria) {
        final numReactivos = _reactivosPorCategoria[categoria.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCategoryListTile(categoria, numReactivos, isMobile),
        );
      }).toList(),
    );
  }

  /// Card compacto para grid (tablet/mobile)
  Widget _buildCategoryCardCompacto(CategoryModelV2 categoria) {
    final numReactivos = _reactivosPorCategoria[categoria.id] ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetallesCategoria(categoria, numReactivos),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.08),
                Colors.purple.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono
                Text(categoria.icono, style: const TextStyle(fontSize: 32)),
                SizedBox(height: 8),

                // Nombre
                Text(
                  categoria.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),

                // Descripción
                Expanded(
                  child: Text(
                    categoria.descripcion,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8),

                // Badge de reactivos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: numReactivos > 0
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$numReactivos 📝',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: numReactivos > 0
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card grande para web - Más visual y atractivo
  Widget _buildCategoryCardGrande(CategoryModelV2 categoria) {
    final numReactivos = _reactivosPorCategoria[categoria.id] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _mostrarDetallesCategoria(categoria, numReactivos),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.purple.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono grande
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    categoria.icono,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
                const SizedBox(height: 16),

                // Nombre
                Text(
                  categoria.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Descripción
                Text(
                  categoria.descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 16),

                // Badge de reactivos grande
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: numReactivos > 0
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: numReactivos > 0
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        numReactivos > 0 ? '✅' : '⚠️',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$numReactivos ${numReactivos == 1 ? 'Reactivo' : 'Reactivos'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: numReactivos > 0
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ListTile compacto para lista
  Widget _buildCategoryListTile(CategoryModelV2 categoria, int numReactivos, bool isMobile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _mostrarDetallesCategoria(categoria, numReactivos),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        leading: Text(
          categoria.icono,
          style: TextStyle(fontSize: isMobile ? 24 : 28),
        ),
        title: Text(
          categoria.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
        subtitle: Text(
          categoria.descripcion,
          style: TextStyle(fontSize: isMobile ? 10 : 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: numReactivos > 0
                ? Colors.green.shade100
                : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$numReactivos',
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.bold,
              color: numReactivos > 0
                  ? Colors.green.shade900
                  : Colors.orange.shade900,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesCategoria(CategoryModelV2 categoria, int numReactivos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(categoria.icono, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(categoria.nombre),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(categoria.descripcion),
              const SizedBox(height: 16),
              const Text(
                'ID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                categoria.id,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estadísticas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Reactivos:', numReactivos.toString()),
                    _buildStatRow('Tests realizados:', '0'),
                    _buildStatRow('Acierto promedio:', '0%'),
                    _buildStatRow('Dificultad promedio:', 'Media'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
