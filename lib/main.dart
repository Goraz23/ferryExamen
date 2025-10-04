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

  double get porcentaje =>
      (aforo / limiteEfectivo).clamp(0.0, 1.0);

  void aplicarCapacidad() {
    final n = int.tryParse(capCtrl.text.trim());
    if (n == null || n <= 0) {
      _msg('Ingresa un número válido');
      return;
    }
    setState(() {
      capacidadIngresada = n;
      if (aforo > limiteEfectivo) aforo = limiteEfectivo;
      capacidadBloqueada = true; // 🔒 bloquear edición
      historial.insert(0, 'Capacidad ingresada: $capacidadIngresada (tope real: $topeFerry)');
    });
  }

  void cambiar(int cantidad) {
    if (aforo == 0 && cantidad < 0) {
      _msg('El aforo ya está en 0');
      return;
    }
    int nuevo = (aforo + cantidad).clamp(0, limiteEfectivo);
    
    if(nuevo == aforo && cantidad > 0) {
      _msg('No se puede superar el límite de $limiteEfectivo');
      return;
    }

    setState(() {
      aforo = nuevo;
      historial.insert(0, 'Cambio de aforo: ${cantidad > 0 ? '+' : ''}$cantidad -> $aforo/$limiteEfectivo');
    });
  }

  void reiniciar() {
    setState(() {
      aforo = 0;
      capacidadBloqueada = false; 
      historial.insert(0, 'Reinicio del aforo');
    });
  }

  Widget foco(Color color, bool encendido) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: encendido ? color : color.withOpacity(0.25),
        ),
      );

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
          children:[
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

            // Estado + semáforo
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

            // Botones
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

            // Historial
            Expanded(
              child: historial.isEmpty
                  ? const Center(child: Text('Sin eventos'))
                  : ListView.builder(
                      itemCount: historial.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(historial[i]),
                      ),
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
