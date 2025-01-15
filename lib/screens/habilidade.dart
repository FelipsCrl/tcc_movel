import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Habilidade extends StatefulWidget {
  final String name;
  final String cpf;
  final String email;
  final String password;
  final List<dynamic> habilidades;

  // Construtor que recebe os dados
  Habilidade({
    required this.name,
    required this.cpf,
    required this.email,
    required this.password,
    required this.habilidades,
  });
  @override
  _HabilidadeState createState() => _HabilidadeState();
}

class _HabilidadeState extends State<Habilidade> {
  List<String> _selectedOptions = [];
  List<dynamic> _options = [];

  Future<void> _cadastro() async {
    final String name = widget.name;
    final String cpf = widget.cpf;
    final String email = widget.email;
    final String password = widget.password;

    List<int> habilidadesIds = [];
    for (var habilidade in _selectedOptions) {
      var habilidadeEncontrada = _options.firstWhere(
              (habilidadeItem) => habilidadeItem['descricao_habilidade'] == habilidade,
          orElse: () => null
      );
      if (habilidadeEncontrada != null) {
        habilidadesIds.add(habilidadeEncontrada['id_habilidade']);
      }
    }
    if(_selectedOptions.isNotEmpty){
      try {
        final Dio _dio = Dio();
        print(habilidadesIds);
        final response = await _dio.post(
          'http://127.0.0.1:8000/api/cadastro',
          data: {
            'nome': name,
            'cpf': cpf,
            'email': email,
            'senha': password,
            'habilidades': habilidadesIds,
          },
        );
        if (response.statusCode == 200) {
          Navigator.pushNamed(context, '/login');
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          Map<String, dynamic> errors = e.response?.data['errors'];
          String errorMessage = errors.values
              .map((messages) => messages.join('\n'))
              .join('\n'); // Concatena todas as mensagens

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível criar uma conta!'),
              backgroundColor: Colors.red,),
          );
          print('Erro ao se conectar à API: $e');
        }
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escolha ao menos uma habilidade!'),backgroundColor: Colors.grey,),
      );
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
    _options = widget.habilidades;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Habilidade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.lightBlueAccent),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
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
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(70),
                      topLeft: Radius.circular(70),
                    )),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.5,
                padding: EdgeInsets.only(top: 25),
                child: Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1.5,
                      height: 30,
                      margin: EdgeInsets.only(top: 0),
                      padding: EdgeInsets.only(
                          top: 0, bottom: 4),
                      child: Center(
                        child: Text(
                          "Qual(is) habilidade(s) você tem?",
                          style: TextStyle(fontWeight: FontWeight.w400, color: Colors.grey[800], fontSize: 18),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Wrap(
                        spacing: 4.0,
                        runSpacing: 3.0,
                        alignment: WrapAlignment.center,
                        children: _buildChoiceChips(),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      margin: EdgeInsets.only(top: 15),
                      padding: EdgeInsets.only(top: 4, bottom: 4),
                      child: ElevatedButton(
                        child: Text("Criar conta", style: TextStyle(color: Colors.white)),
                        onPressed: _cadastro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shadowColor: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
    );
  }

  List<Widget> _buildChoiceChips() {
    return _options.map((option) {
      final descricaoHabilidade = option['descricao_habilidade'];  // A descrição da habilidade
      final isSelected = _selectedOptions.contains(descricaoHabilidade);  // Verificar se a descrição está na lista de selecionadas

      return ChoiceChip(
        label: Text(
          descricaoHabilidade,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        selected: isSelected,
        checkmarkColor: Colors.white,
        onSelected: (bool selected) {
          setState(() {
            if (selected) {
              // Adiciona a descrição da habilidade à lista
              if (!_selectedOptions.contains(descricaoHabilidade)) {
                _selectedOptions.add(descricaoHabilidade);
              }
            } else {
              // Remove a descrição da habilidade da lista
              _selectedOptions.remove(descricaoHabilidade);
            }
          });
        },
        selectedColor: Colors.lightBlueAccent[200],
        backgroundColor: Colors.grey[400],
      );
    }).toList();
  }

}
