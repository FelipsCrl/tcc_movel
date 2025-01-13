import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String? token;

  Future<void> _initialize() async {
    await _recuperarToken();
    _dados();
  }

  Future<void> _dados() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get(
        'http://127.0.0.1:8000/api/dadosVoluntario',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Instância de PSharedPreferences
        PSharedPreferences prefs = PSharedPreferences();

        // Salvando os dados no SharedPreferences
        await prefs.setJson(prefs.VOLUNTARIO, response.data['data']);
        print(response.data['data']);

        // Login bem-sucedido
        Navigator.pushNamed(context, '/navegar');
      }

    } catch (e) {
      print('Erro ao buscar dados do voluntário: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue,
      alignment: Alignment.center,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Future<void> _recuperarToken() async {
    String? tokenRecuperado = await PSharedPreferences().getString("USUARIO"); // Pegue o token direto do SharedPreferences
    setState(() {
      token = tokenRecuperado;
    });
  }

  /*Future<void> _recuperarDadosVoluntario() async {
    PSharedPreferences prefs = PSharedPreferences();
    Map<String, dynamic> _dadosVoluntario = await prefs.getJson(prefs.VOLUNTARIO);
  }*/

}