import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/screens/busca_instituicao.dart';
import 'package:maos_solidarias_dm/screens/cadastro.dart';
import 'package:maos_solidarias_dm/screens/doacao.dart';
import 'package:maos_solidarias_dm/screens/esqueceu_senha.dart';
import 'package:maos_solidarias_dm/screens/habilidade.dart';
import 'package:maos_solidarias_dm/screens/evento.dart';
import 'package:maos_solidarias_dm/screens/instituicao.dart';
import 'package:maos_solidarias_dm/screens/login.dart';
import 'package:maos_solidarias_dm/screens/navegar.dart';
import 'package:maos_solidarias_dm/screens/perfil.dart';
import 'package:maos_solidarias_dm/screens/teste_acao.dart';
import 'package:maos_solidarias_dm/screens/validacao.dart';
import 'package:maos_solidarias_dm/splash.dart';
//import 'package:maos_solidarias_dm/screens/teste_acao.dart';

Future<void> main() async{
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Mãos Solidárias",
    initialRoute: '/',
    routes: {
      '/login': (context) => Login(),
      '/cadastro': (context) => Cadastro(),
      '/': (context) => Valida(),
      //'/habilidade': (context) => Habilidade(),
      '/splash': (context) => Splash(),
      '/doacao': (context) => Doacao(),
      '/navegar': (context) => Navegar(),
      '/busca': (context) => Busca(),
      '/evento': (context) => Evento(),
      '/perfil': (context) => Perfil(),
      '/esqueceu': (context) => Esqueceu(),
      '/teste': (context) => HomePage()
    },
    onGenerateRoute: (settings) {
      if (settings.name == '/instituicao') {
        final Map<String, dynamic> instituicao = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => Instituicao(instituicao: instituicao),
        );
      }
      return null;
    },
    theme: ThemeData(
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Colors.lightBlueAccent[100], // Cor de seleção do texto
        selectionHandleColor: Colors.lightBlueAccent, // Cor da alça de seleção
      ),
      primarySwatch: Colors.blue,
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(10),
        hintStyle: const TextStyle(color: Colors.black45),
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIconColor: Colors.lightBlue,
        suffixIconColor: Colors.lightBlue,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.lightBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  )
  );
}
