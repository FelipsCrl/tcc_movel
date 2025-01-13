import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Valida extends StatelessWidget {

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("USUARIO"); // Verifica se o token existe
    return token != null && token.isNotEmpty; // Retorna true se o token estiver presente
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tela de carregamento enquanto verifica o login
          return Scaffold(
            backgroundColor: Colors.lightBlue,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          // Usuário está logado, vá para a tela inicial
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/navegar'));
          return Container(); // Retorna um container vazio enquanto redireciona
        } else {
          // Usuário não está logado, vá para a tela de login
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
          return Container(); // Retorna um container vazio enquanto redireciona
        }
      },
    );
  }
}
