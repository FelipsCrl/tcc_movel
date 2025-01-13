import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Esqueceu extends StatefulWidget {
  @override
  _EsqueceuState createState() => _EsqueceuState();
}

class _EsqueceuState extends State<Esqueceu> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _esqueceuSenha() async {
    try {
      final Dio _dio = Dio();
      Response response = await _dio.post(
        'http://127.0.0.1:8000/api/esqueceu',
        data: FormData.fromMap({
          'email': _emailController.text,
        },),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/login');
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifique na sua caixa de email!'),backgroundColor: Colors.lightBlue,),
      );
      print('Erro ao redefinir senha: $e');
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Redefinir senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400,)),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: const BoxDecoration(color: Colors.lightBlueAccent),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/3,
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
                    )
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/1.5,
                padding:  const EdgeInsets.only(top: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width/1.5,
                        height: 25,
                        margin: const EdgeInsets.only(top: 0),
                        padding: const EdgeInsets.only(
                            top: 0, bottom: 4
                        ),
                        child: Center(child: Text("Preencha o email para redefinir a senha",style: TextStyle(color: Colors.grey[800]),)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.only(
                            top: 4, bottom: 4
                        ),
                        width: MediaQuery.of(context).size.width/1.5,
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
                        width: MediaQuery.of(context).size.width/1.5,
                        height: 50,
                        margin: const EdgeInsets.only(top: 25),
                        padding: const EdgeInsets.only(
                            top: 4, bottom: 4
                        ),
                        child: ElevatedButton(
                          child: const Text("Redefinir senha",style: TextStyle(color: Colors.white),),
                          onPressed: (){
                            if (_formKey.currentState!.validate()) {
                              _esqueceuSenha();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            shadowColor: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width/1.5,
                        height: 50,
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.only(
                            top: 4, bottom: 4
                        ),
                        child: ElevatedButton(
                          child: const Text("Fazer Login",style: TextStyle(color: Colors.white),),
                          onPressed: (){
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white30,
                            shadowColor: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              )
            ],
          ),
        )
    );
  }
}


