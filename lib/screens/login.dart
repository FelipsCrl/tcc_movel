import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _visivel = true;

  void _senhaVisivel() {
    setState(() {
      _visivel = !_visivel;
    });
  }

  void _portraitModeOnly() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _portraitModeOnly();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/loginApi',
          data: FormData.fromMap({
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          // Aqui pegamos a resposta JSON como um mapa
          Map<String, dynamic> jsonResponse = response.data;

          // Passa o token do JSON para a função _inserir
          _inserir(jsonResponse['data']['tokenAuth']);

          // Login bem-sucedido
          Navigator.pushNamed(context, '/splash');
        }
      } on DioException catch (e) {
        if(e.response?.statusCode == 400){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.response?.data['message'])),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível logar no sistema!'),backgroundColor: Colors.red,),
          );
          print('Erro ao se conectar à API: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(color: Colors.lightBlueAccent),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xff0545ab),
                      Colors.lightBlueAccent,
                    ],
                  ),
                ),
                child: Image.asset(
                  "img/mao_logo2.png",
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(70),
                    topLeft: Radius.circular(70),
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.5,
                padding: const EdgeInsets.only(top: 15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: 25,
                        margin: const EdgeInsets.only(top: 0),
                        padding: const EdgeInsets.only(top: 0, bottom: 4),
                        child: Center(
                          child: Text("Insira os dados necessários",
                              style: TextStyle(color: Colors.grey[800])),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        width: MediaQuery.of(context).size.width / 1.5,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.black45,
                          decoration: const InputDecoration(
                            hintText: "Digite...",
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira seu email';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: TextFormField(
                          controller: _passwordController,
                          cursorColor: Colors.black45,
                          obscureText: _visivel,
                          decoration: InputDecoration(
                            hintText: "Digite...",
                            labelText: "Senha",
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_visivel
                                  ? Icons.remove_red_eye
                                  : Icons.remove_red_eye_outlined),
                              onPressed: _senhaVisivel,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira sua senha';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: 25,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: InkWell(
                          child: Center(
                            child: Text("Esqueceu a senha?",
                                style: TextStyle(color: Colors.lightBlue[600])),
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/esqueceu');
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: 50,
                        margin: const EdgeInsets.only(top: 25),
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: ElevatedButton(
                          child: const Text("Entrar",
                              style: TextStyle(color: Colors.white)),
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            shadowColor: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: 50,
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: ElevatedButton(
                          child: const Text("Criar Conta",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.pushNamed(context, '/cadastro');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white30,
                            shadowColor: Colors.black,
                          ),
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

  void _inserir(String token) async {
    PSharedPreferences prefs = PSharedPreferences();
    await prefs.setString(prefs.USUARIO, token); // Armazena o token
  }
}
