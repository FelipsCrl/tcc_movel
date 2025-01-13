import 'package:brasil_fields/brasil_fields.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maos_solidarias_dm/screens/habilidade.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _options = [];

  bool _visivel = true;

  void _senhaVisivel() {
    setState(() {
      _visivel = !_visivel;
    });
  }

  Future<void> _listagemHabilidades() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaHabilidade');
      setState(() {
        _options = response.data['data'];
      });
    } catch (e) {
      print('Erro ao buscar habilidades: $e');
    }
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
    _listagemHabilidades();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cadastro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400,)),
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
                      Colors.lightBlueAccent
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            height: 25,
                            margin: const EdgeInsets.only(top: 0),
                            padding: const EdgeInsets.only(top: 0, bottom: 4),
                            child: Center(child: Text("Insira os dados necessários", style: TextStyle(color: Colors.grey[800]),)),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              cursorColor: Colors.black45,
                              decoration: const InputDecoration(
                                hintText: "Digite...",
                                labelText: "Nome",
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu nome';
                                }
                                return null;
                              },
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              cursorColor: Colors.black45,
                              decoration: const InputDecoration(
                                hintText: "Digite...",
                                labelText: "CPF",
                                prefixIcon: Icon(Icons.contact_mail_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu CPF';
                                }
                                if (!UtilBrasilFields.isCPFValido(value)) {
                                  return 'CPF inválido';
                                }
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly, // Permite apenas números
                                CpfInputFormatter(), // Aplica a formatação de CPF
                              ],
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
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
                                // Expressão regular para validar e-mail
                                String pattern =
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                RegExp regex = RegExp(pattern);
                                if (!regex.hasMatch(value)) {
                                  return 'Por favor, insira um e-mail válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            margin: const EdgeInsets.only(top: 3),
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
                                  icon: Icon(
                                    _visivel ? Icons.remove_red_eye : Icons.remove_red_eye_outlined,
                                  ),
                                  onPressed: _senhaVisivel,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua senha';
                                }
                                else if (value.length < 6) {
                                  return 'Por favor, mínimo de 6 caracteres na senha';
                                }
                                return null;
                              },
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            height: 50,
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: ElevatedButton(
                              child: const Text("Próximo passo", style: TextStyle(color: Colors.white),),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Habilidade(
                                          name: _nameController.text,
                                          cpf: _cpfController.text,
                                          email: _emailController.text,
                                          password: _passwordController.text,
                                          habilidades: _options
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                                shadowColor: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            height: 50,
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: ElevatedButton(
                              child: const Text("Fazer Login", style: TextStyle(color: Colors.white),),
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white30,
                                shadowColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
