import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aforo Ferry',
      debugShowCheckedModeBanner: false,
      home: const AforoPage(),
    );
  }
}

class AforoPage extends StatefulWidget {
  const AforoPage({super.key});
  @override
  State<AforoPage> createState() => _AforoPageState();
}

class _AforoPageState extends State<AforoPage> {
  final int topeFerry = 800;
  final TextEditingController capCtrl = TextEditingController(text: '100');

  int capacidadIngresada = 100;
  int aforo = 0;
  bool capacidadBloqueada = false;
  List<String> historial = [];

  int get limiteEfectivo =>
      capacidadIngresada > topeFerry ? topeFerry : capacidadIngresada;

  double get porcentaje => (aforo / limiteEfectivo).clamp(0.0, 1.0);

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _addHist(String mensaje) {
    final now = DateTime.now();
    setState(() {
      historial.insert(0, '[${_hhmm(now)}] $mensaje');
    });
  }

  void aplicarCapacidad() {
    final n = int.tryParse(capCtrl.text.trim());
    if (n == null || n <= 0) {
      _msg('Ingresa un número válido');
      return;
    }
    setState(() {
      capacidadIngresada = n;
      if (aforo > limiteEfectivo) aforo = limiteEfectivo;
      capacidadBloqueada = true;
    });
    _addHist('Capacidad ingresada: $capacidadIngresada (tope real: $topeFerry)');
  }

  void cambiar(int cantidad) {
    if (aforo == 0 && cantidad < 0) {
      _msg('El aforo ya está en 0');
      return;
    }
    final nuevo = (aforo + cantidad).clamp(0, limiteEfectivo);
    if (nuevo == aforo && cantidad > 0) {
      _msg('No se puede superar el límite de $limiteEfectivo');
      return;
    }
    setState(() {
      aforo = nuevo;
    });
    _addHist('Cambio de aforo: ${cantidad > 0 ? '+' : ''}$cantidad -> $aforo/$limiteEfectivo');
  }

  void reiniciar() {
    setState(() {
      aforo = 0;
      capacidadBloqueada = false;
    });
    _addHist('Reinicio del aforo');
  }

  Widget foco(Color color, bool encendido) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: encendido ? color : color.withOpacity(0.25),
        ),
      );

  IconData _iconFor(String s) {
    if (s.contains('Capacidad ingresada')) return Icons.settings_input_component_rounded;
    if (s.contains('Reinicio')) return Icons.restart_alt_rounded;
    if (s.contains('Cambio de aforo')) return Icons.sync_alt_rounded;
    return Icons.info_outline_rounded;
  }

  Color _colorFor(String s) {
    if (s.contains('Capacidad ingresada')) return Colors.blue;
    if (s.contains('Reinicio')) return Colors.grey;
    if (s.contains('Cambio de aforo')) {
      final m = RegExp(r'Cambio de aforo:\s*([+\-]\d+)').firstMatch(s);
      if (m != null && m.group(1)!.startsWith('+')) return Colors.green;
      return Colors.orange;
    }
    return Colors.blueGrey;
  }

  ({String time, String text}) _splitTime(String raw) {
    final m = RegExp(r'^\[(\d{2}:\d{2})\]\s*(.*)$').firstMatch(raw);
    if (m != null) {
      return (time: m.group(1)!, text: m.group(2)!);
    }
    return (time: '', text: raw);
  }

  String? _extractPercent(String raw) {
    final m = RegExp(r'->\s*(\d+)\s*/\s*(\d+)').firstMatch(raw);
    if (m == null) return null;
    final cur = int.tryParse(m.group(1)!);
    final lim = int.tryParse(m.group(2)!);
    if (cur == null || lim == null || lim == 0) return null;
    final p = ((cur / lim) * 100).clamp(0, 100);
    return '$p%';
  }

  @override
  Widget build(BuildContext context) {
    bool verde = porcentaje < 0.60;
    bool amarillo = porcentaje >= 0.60 && porcentaje < 0.90;
    bool rojo = porcentaje >= 0.90;

    return Scaffold(
      appBar: AppBar(title: const Text('Aforo Ferry (tope 800)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://happyshuttlecancun.com/images/ultramar-ferry.jpg',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: capCtrl,
                    readOnly: capacidadBloqueada,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ingresa la capacidad del ferry, ej. 100',
                      helperText: 'Tope real: $topeFerry',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => aplicarCapacidad(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: capacidadBloqueada ? null : aplicarCapacidad,
                  child: const Text('Aplicar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aforo: $aforo / $limiteEfectivo'),
                          LinearProgressIndicator(value: porcentaje),
                          Text('Porcentaje: ${(porcentaje * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        foco(Colors.green, verde),
                        foco(Colors.amber, amarillo),
                        foco(Colors.red, rojo),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(onPressed: () => cambiar(1), child: const Text('+1')),
                ElevatedButton(onPressed: () => cambiar(2), child: const Text('+2')),
                ElevatedButton(onPressed: () => cambiar(5), child: const Text('+5')),
                ElevatedButton(onPressed: () => cambiar(-1), child: const Text('-1')),
                ElevatedButton(onPressed: () => cambiar(-5), child: const Text('-5')),
                OutlinedButton(onPressed: reiniciar, child: const Text('Reiniciar')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: historial.isEmpty
                  ? const Center(child: Text('Sin eventos'))
                  : ListView.separated(
                      itemCount: historial.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final raw = historial[i];
                        final parts = _splitTime(raw);
                        final color = _colorFor(raw);
                        final icon = _iconFor(raw);
                        final percent = _extractPercent(raw);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color.withOpacity(0.25)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.12),
                              foregroundColor: color,
                              child: Icon(icon),
                            ),
                            title: Text(
                              parts.text,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: parts.time.isEmpty
                                ? null
                                : Text('a las ${parts.time}'),
                            trailing: percent == null
                                ? null
                                : Chip(
                                    label: Text(percent),
                                    backgroundColor: color.withOpacity(0.10),
                                    side: BorderSide(color: color.withOpacity(0.22)),
                                    labelStyle: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }
}
