import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';

class Perfil extends StatefulWidget {
  @override
  _PerfilState createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _cpfController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _senhaAtualController = TextEditingController();
  TextEditingController _senhaNovaController = TextEditingController();
  TextEditingController _senhaConfirmaController = TextEditingController();
  TextEditingController _telefoneController = TextEditingController();
  TextEditingController _whatsappController = TextEditingController();
  TextEditingController _cepController = TextEditingController();
  TextEditingController _estadoController = TextEditingController();
  TextEditingController _cidadeController = TextEditingController();
  TextEditingController _ruaController = TextEditingController();
  TextEditingController _numeroController = TextEditingController();
  TextEditingController _bairroController = TextEditingController();
  TextEditingController _complementoController = TextEditingController();

  String? token;
  List<dynamic> _dadosVoluntario = [];
  List<dynamic> _habilidades = [];
  List<dynamic> _solicitacoes = [];
  List<String> _volunteerSkills = [];

  bool _isLoading = true;
  bool noRead = true;

  int currentPageIndex = 0;

  Widget _selectePage(){
    if(currentPageIndex == 0) {
      return _dataPage(_dadosVoluntario[0]);
    }
    else if(currentPageIndex == 1) {
      return _habilidadePage(_dadosVoluntario[0]);
    }
    /*else if(currentPageIndex == 2) {
      return _expPage();
    }*/
    else if(currentPageIndex == 2) {
      return _solicitaPage(_solicitacoes);
    }
    else{
      return const Center(
        child: Text('Página não encontrada'),
      );
    }
  }

  final List<Color> _containerColors = [
    Colors.black12,
    Colors.white,
    Colors.white,
    Colors.white,
  ];

  void _changeColor(int index) {
    setState(() {
      for (int i = 0; i < _containerColors.length; i++) {
        if (i == index) {
          _containerColors[i] = Colors.black12;
        } else {
          _containerColors[i] = Colors.white;
        }
      }
    });
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
      // Instância de PSharedPreferences
      PSharedPreferences prefs = PSharedPreferences();

      // Salvando os dados no SharedPreferences
      await prefs.setJson(prefs.VOLUNTARIO, response.data['data']);
      setState(() {
        _dadosVoluntario = response.data['data'];
        _volunteerSkills = List<String>.from(
            response.data['data'][0]['habilidades']
                .map((habilidade) => habilidade['descricao_habilidade'])
        );
        _isLoading = false;
        _nomeController.text = _dadosVoluntario[0]['usuario']['name'] ?? '';
        _cpfController.text = _dadosVoluntario[0]['cpf_voluntario'] ?? '';
        _emailController.text = _dadosVoluntario[0]['usuario']['email'] ?? '';
        _telefoneController.text = _dadosVoluntario[0]['contato']['telefone_contato'] ?? '';
        _whatsappController.text = _dadosVoluntario[0]['contato']['whatsapp_contato'] ?? '';
        _cepController.text = _dadosVoluntario[0]['endereco']['cep_endereco'] ?? '';
        _estadoController.text = _dadosVoluntario[0]['endereco']['estado_endereco'] ?? '';
        _cidadeController.text = _dadosVoluntario[0]['endereco']['cidade_endereco'] ?? '';
        _ruaController.text = _dadosVoluntario[0]['endereco']['logradouro_endereco'] ?? '';
        _numeroController.text = _dadosVoluntario[0]['endereco']['numero_endereco']?.toString() ?? '';
        _bairroController.text = _dadosVoluntario[0]['endereco']['bairro_endereco'] ?? '';
        _complementoController.text = _dadosVoluntario[0]['endereco']['complemento_endereco'] ?? '';
      });

    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar dados do voluntário: $e');
    }
  }

  Future<void> _listagemHabilidades() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaHabilidade');
      setState(() {
        _habilidades = response.data['data'];
      });
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar habilidades: $e');
    }
  }

  Future<void> _listagemSolicitacoes() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaSolicitacao',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      setState(() {
        _solicitacoes = response.data['data'];
      });
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar solicitações: $e');
    }
  }

  Future<void> _salvarHabilidades() async {
    List<int> habilidadesIds = [];
    for (var habilidade in _volunteerSkills) {
      var habilidadeEncontrada = _habilidades.firstWhere(
              (habilidadeItem) => habilidadeItem['descricao_habilidade'] == habilidade,
          orElse: () => null
      );
      if (habilidadeEncontrada != null) {
        habilidadesIds.add(habilidadeEncontrada['id_habilidade']);
      }
    }
    try {
      final Dio _dio = Dio();
      final response = await _dio.post(
        'http://127.0.0.1:8000/api/atualizaHabilidades',
        data: {
          'habilidades': habilidadesIds,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        _dados();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message']),
            backgroundColor: Colors.green,),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar as habilidades!'),backgroundColor: Colors.red,),
      );
      print('Erro ao salvar habilidades: $e');
    }
  }

  Future<void> _atualizaCredencial() async {
    if(_nomeController.text.isNotEmpty){
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/atualizaCredenciais',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'nome': _nomeController.text,
          },),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green,),
          );
          _dados();
        }
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar as credenciais!'),backgroundColor: Colors.red,),
        );
        print('Erro ao se inscrever em evento: $e');
      }
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nome é obrigatório!')),
      );
    }
  }

  Future<void> _atualizaContato() async {
    if (_telefoneController.text.isNotEmpty) {
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/atualizaContato',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'telefone': _telefoneController.text,
            'whatsapp': _whatsappController.text.isNotEmpty ? _whatsappController.text : null,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.green,
            ),
          );
          _dados(); // Atualiza os dados após o sucesso
        }
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível atualizar o contato!'),
            backgroundColor: Colors.red,
          ),
        );
        print('Erro ao atualizar contato: $e');
      }
    } else {
      // Exibe mensagem informando que o telefone é obrigatório
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O telefone é obrigatório!')),
      );
    }
  }

  Future<void> _atualizaEndereco() async {
    // Verificar se todos os campos estão preenchidos
    if (_ruaController.text.isNotEmpty &&
        _cepController.text.isNotEmpty &&
        _numeroController.text.isNotEmpty &&
        _bairroController.text.isNotEmpty &&
        _cidadeController.text.isNotEmpty &&
        _estadoController.text.isNotEmpty) {
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/atualizaEndereco',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'rua': _ruaController.text,
            'cep': _cepController.text,
            'numero': _numeroController.text,
            'bairro': _bairroController.text,
            'cidade': _cidadeController.text,
            'estado': _estadoController.text,
            'complemento': _complementoController.text, // Complemento pode ser opcional
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message']),
              backgroundColor: Colors.green,
            ),
          );
          _dados(); // Função para atualizar os dados, se necessário
        }
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível atualizar o endereço!'),
            backgroundColor: Colors.red,
          ),
        );
        print('Erro ao atualizar endereço: $e');
      }
    } else {
      // Mensagem para o usuário preencher os campos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os dados corretamente!')),
      );
    }
  }

  Future<void> _atualizaSenha() async {
    if(_senhaNovaController.text == _senhaConfirmaController.text){
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/atualizaSenha',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'senhaNova': _senhaNovaController.text,
            'senhaAntiga': _senhaAtualController.text,
          },),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green,),
          );
          _dados();
          setState(() {
            _senhaConfirmaController.clear();
            _senhaNovaController.clear();
            _senhaAtualController.clear();
          });
        }
      } on DioException catch (e) {
        if(e.response?.statusCode == 400){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.response?.data['message']), backgroundColor: Colors.red,),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível atualizar a senha!'),backgroundColor: Colors.red,),
          );
          print('Erro ao atualizar senha: $e');
        }
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas não coincidem!'),backgroundColor: Colors.red,),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final Dio _dio = Dio();
      Response response = await _dio.get('http://127.0.0.1:8000/api/logoutApi',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        PSharedPreferences prefs = PSharedPreferences();
        await prefs.clearAll();
        Navigator.pushNamed(context, '/login');
      }
    } on DioException catch (e) {
      if(e.response?.statusCode == 400){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['message'])),
        );
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível sair da conta!'),backgroundColor: Colors.red,),
        );
        print('Erro ao se conectar à API: $e');
      }
    }
  }

  Future<void> _initialize() async {
    //_recuperarDadosVoluntario();
    await _recuperarToken();
    _dados();
    _listagemHabilidades();
    _listagemSolicitacoes();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Colors.lightBlue),
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(color: Colors.lightBlue),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 3,
                  decoration: const BoxDecoration(
                    color: Colors.lightBlue,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 65.0,
                        backgroundColor: Colors.white,
                        child: Image.asset(
                          'img/user.png',
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _dadosVoluntario[0]['usuario']['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Rubik',
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          child: Container(
                            width:
                            MediaQuery.of(context).size.width / 2,
                            padding: const EdgeInsets.only(top: 0),
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _containerColors[0],
                            ),
                            child: const Text(
                              'Dados Pessoais',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              currentPageIndex = 0;
                            });
                            _changeColor(0);
                          },
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          child: Container(
                            width:
                            MediaQuery.of(context).size.width / 2,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _containerColors[1],
                            ),
                            child: const Text(
                              'Habilidades',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              currentPageIndex = 1;
                            });
                            _changeColor(1);
                          },
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          child: Container(
                            width:
                            MediaQuery.of(context).size.width / 2,
                            height: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _containerColors[2],
                            ),
                            child: const Text(
                              'Solicitações',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              currentPageIndex = 2;
                            });
                            _changeColor(2);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _selectePage(),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16.0,
          right: 16.0,
          child: IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              _alertLogout(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _dataPage(dynamic dados){
    return(
        Expanded(
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(color: Colors.white),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Credenciais",
                          style: TextStyle(
                            fontSize: 19.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        IconButton(
                          onPressed: (){
                            noRead = false;
                            _exibeEdit(context, _credencial(dados, exibirCPF: false, exibirEmail: false), _atualizaCredencial);
                          },
                          icon: const Icon(Icons.edit, color: Colors.lightBlue,),
                        )
                      ],
                    ),
                    _credencial(dados),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Senha",
                          style: TextStyle(
                            fontSize: 19.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                        onPressed: (){
                          _exibeEditarSenha(context);
                        },
                        child: Text('Alterar senha',
                          style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontFamily: 'Open Sans',
                          ),
                        ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shadowColor: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Contato",
                          style: TextStyle(
                            fontSize: 19.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        IconButton(
                          onPressed: (){
                            noRead = false;
                            _exibeEdit(context, _contato(dados['contato']), _atualizaContato);
                          },
                          icon: const Icon(Icons.edit, color: Colors.lightBlue,),
                        )
                      ],
                    ),
                    _contato(dados['contato']),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Endereço",
                          style: TextStyle(
                            fontSize: 19.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                            fontFamily: 'Rubik',
                          ),
                        ),
                        IconButton(
                          onPressed: (){
                            noRead = false;
                            _exibeEdit(context, _endereco(dados['endereco']), _atualizaEndereco);
                          },
                          icon: const Icon(Icons.edit, color: Colors.lightBlue,),
                        )
                      ],
                    ),
                    _endereco(dados['endereco']),
                  ],
                ),
              )
            ],
          ),
        )
    )
    );
  }

  /*Widget _expPage(){
    return (
        Expanded(
            child: Container(//
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(color: Colors.white),
                child: ListView(
                    children: [
                      Card(
                        color: const Color(0xe3f4f4f5),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                                child: const Column(
                                  children: [
                                    Text("Dia XX/XX/XX",
                                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xed171718),fontFamily: 'Rubik'),
                                    ),
                                    Text("Você ajudou com uma doação, para a Associação das Mãos Unidas",
                                      style: TextStyle(color: Color(0xed171718),fontFamily: 'Rubik'),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ]
                )
            )
        )
    );
  }*/

  Widget _solicitaPage(dynamic solicitacoes) {
    return Expanded(
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView.builder(
          itemCount: solicitacoes.length,
          itemBuilder: (context, index) {
            final solicitacao = solicitacoes[index] as Map<String, dynamic>;

            // Tratamento de 'situacao'
            int situacao = solicitacao['situacao'] is int
                ? solicitacao['situacao']
                : int.tryParse(solicitacao['situacao'].toString()) ?? -1;

            String situacaoTexto;
            Color situacaoCor;

            switch (situacao) {
              case 0:
                situacaoTexto = 'Aguardando';
                situacaoCor = Colors.blue;
                break;
              case -1:
                situacaoTexto = 'Negada';
                situacaoCor = Colors.red;
                break;
              default:
                situacaoTexto = 'Aprovada';
                situacaoCor = Colors.green;
            }

            String tipoSolicitacao = solicitacao.containsKey('categoria')
                ? "uma doação de ${solicitacao['categoria']}"
                : "um voluntariado em ${solicitacao['habilidade']}";

            return Card(
              color: const Color(0xFFE3F4F4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Dia ${solicitacao['data']?.split(' ')[0] ?? 'Data não disponível'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171718),
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "Você solicitou $tipoSolicitacao em ${solicitacao['nome_instituicao']}",
                        style: const TextStyle(
                          color: Color(0xFF171718),
                          fontFamily: 'Rubik',
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Situação: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171718),
                            fontFamily: 'Rubik',
                          ),
                        ),
                        Text(
                          situacaoTexto,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: situacaoCor,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _habilidadePage(dynamic dados){
    return (
        Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 30),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(color: Colors.white),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: Wrap(
                        spacing: 4.0,
                        runSpacing: 3.0,
                        alignment: WrapAlignment.center,
                        children: _buildChoiceChips(),
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: 50,
                    margin: const EdgeInsets.only(top: 15),
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: ElevatedButton(
                      onPressed: _salvarHabilidades,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shadowColor: Colors.black,
                      ),
                      child: const Text("Salvar", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
        )
    );
  }

  List<Widget> _buildChoiceChips() {
    return _habilidades.map((option) {
      // Verifica se a habilidade já foi selecionada
      final isSelected = _volunteerSkills.contains(option['descricao_habilidade']);

      return ChoiceChip(
        label: Text(
          option['descricao_habilidade'],
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        selected: isSelected,
        checkmarkColor: Colors.white,
        onSelected: (bool selected) {
          setState(() {
            if (selected) {
              // Adiciona a habilidade à lista do voluntário
              if (!_volunteerSkills.contains(option['descricao_habilidade'])) {
                _volunteerSkills.add(option['descricao_habilidade']);
              }
            } else {
              // Remove a habilidade da lista
              _volunteerSkills.remove(option['descricao_habilidade']);
            }
          });
        },
        selectedColor: Colors.lightBlueAccent[200],
        backgroundColor: Colors.grey[400],
      );
    }).toList();
  }

  Widget _credencial(dynamic dados, {bool exibirCPF = true, bool exibirEmail = true}) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextField(
          readOnly: noRead,
          controller: _nomeController,
          keyboardType: TextInputType.name,
          cursorColor: Colors.black45,
          decoration: InputDecoration(
            hintText: "Digite...",
            hintStyle: const TextStyle(color: Colors.black45),
            label: const Text(
              "Nome",
              style: TextStyle(color: Colors.black54),
            ),
            prefixIcon: const Icon(
              Icons.person,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlueAccent,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlue,
                width: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        if (exibirCPF)
          TextField(
            readOnly: noRead,
            controller: _cpfController,
            cursorColor: Colors.black45,
            decoration: InputDecoration(
              hintText: "Digite...",
              hintStyle: const TextStyle(color: Colors.black45),
              label: const Text(
                "CPF",
                style: TextStyle(color: Colors.black54),
              ),
              prefixIcon: const Icon(
                Icons.contact_mail_rounded,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Colors.lightBlue,
                  width: 2.0,
                ),
              ),
            ),
          ),
        const SizedBox(height: 5),
        if(exibirEmail)
          TextField(
            readOnly: noRead,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: Colors.black45,
            decoration: InputDecoration(
              hintText: "Digite...",
              hintStyle: const TextStyle(color: Colors.black45),
              label: const Text(
                "Email",
                style: TextStyle(color: Colors.black54),
              ),
              prefixIcon: const Icon(
                Icons.email_rounded,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Colors.lightBlueAccent,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Colors.lightBlue,
                  width: 2.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _contato(dynamic contato){
    return Column(
      children: [
        const SizedBox(height: 10),
        TextField(
          readOnly: noRead,
          controller: _telefoneController,
          cursorColor: Colors.black45,
          decoration: InputDecoration(
            hintText: "Digite...",
            hintStyle: const TextStyle(color: Colors.black45),
            label: const Text("Telefone", style: TextStyle(color: Colors.black54)),
            prefixIcon: const Icon(
              Icons.phone_rounded,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlueAccent,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlue,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (value) {
            final formatted = _formatarTelefone(value);
            _telefoneController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Permite apenas números
            LengthLimitingTextInputFormatter(11), // Limita ao máximo de 11 dígitos
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          readOnly: noRead,
          controller: _whatsappController,
          cursorColor: Colors.black45,
          decoration: InputDecoration(
            hintText: "Digite...",
            hintStyle: const TextStyle(color: Colors.black45),
            label: const Text("Whatsapp", style: TextStyle(color: Colors.black54)),
            prefixIcon: const Icon(
              Icons.phone_android_rounded,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlueAccent,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlue,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (value) {
            final formatted = _formatarTelefone(value);
            _whatsappController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Permite apenas números
            LengthLimitingTextInputFormatter(11), // Limita ao máximo de 11 dígitos
          ],
        ),
      ],
    );
  }

  Widget _endereco(dynamic endereco) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Linha para CEP e Estado
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                readOnly: noRead,
                controller: _cepController,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("CEP", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.map_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  final cep = value.replaceAll("-", ""); // Remove qualquer traço antes de formatar
                  if (cep.length > 5) {
                    _cepController.value = TextEditingValue(
                      text: '${cep.substring(0, 5)}-${cep.substring(5)}',
                      selection: TextSelection.collapsed(offset: '${cep.substring(0, 5)}-${cep.substring(5)}'.length),
                    );
                  }
                  if (cep.length == 8) {
                    _buscarEndereco();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 2,
              child: TextField(
                readOnly: noRead,
                controller: _estadoController,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("Estado", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.public_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Linha para Cidade
        TextField(
          readOnly: noRead,
          controller: _cidadeController,
          cursorColor: Colors.black45,
          decoration: InputDecoration(
            hintText: "Digite...",
            hintStyle: const TextStyle(color: Colors.black45),
            label: const Text("Cidade", style: TextStyle(color: Colors.black54)),
            prefixIcon: const Icon(Icons.location_city_rounded),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlueAccent,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Colors.lightBlue,
                width: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Linha para Rua e Número
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                readOnly: noRead,
                controller: _ruaController,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("Rua", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.emoji_transportation_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 1,
              child: TextField(
                readOnly: noRead,
                controller: _numeroController,
                keyboardType: TextInputType.number,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("Nº", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.navigation_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Linha para Bairro e Complemento
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                readOnly: noRead,
                controller: _bairroController,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("Bairro", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.place_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              flex: 3,
              child: TextField(
                readOnly: noRead,
                controller: _complementoController,
                cursorColor: Colors.black45,
                decoration: InputDecoration(
                  hintText: "Digite...",
                  hintStyle: const TextStyle(color: Colors.black45),
                  label: const Text("Complemento", style: TextStyle(color: Colors.black54)),
                  prefixIcon: const Icon(Icons.maps_home_work_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      color: Colors.lightBlue,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _exibeEditarSenha(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Define o tamanho mínimo
                  children: [
                    // Campo para a senha atual
                    TextField(
                      obscureText: true, // Esconde o texto para senhas
                      controller: _senhaAtualController,
                      cursorColor: Colors.black45,
                      decoration: InputDecoration(
                        hintText: "Digite sua senha atual",
                        hintStyle: const TextStyle(color: Colors.black45),
                        label: const Text(
                          "Senha Atual",
                          style: TextStyle(color: Colors.black54),
                        ),
                        prefixIcon: const Icon(Icons.password_rounded),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlueAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlue,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Espaçamento entre os campos
                    // Campo para a nova senha
                    TextField(
                      obscureText: true, // Esconde o texto para senhas
                      cursorColor: Colors.black45,
                      controller: _senhaNovaController,
                      decoration: InputDecoration(
                        hintText: "Digite sua nova senha",
                        hintStyle: const TextStyle(color: Colors.black45),
                        label: const Text(
                          "Nova Senha",
                          style: TextStyle(color: Colors.black54),
                        ),
                        prefixIcon: const Icon(Icons.key_rounded),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlueAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlue,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Espaçamento entre os campos
                    // Campo para confirmar a nova senha
                    TextField(
                      obscureText: true, // Esconde o texto para senhas
                      cursorColor: Colors.black45,
                      controller: _senhaConfirmaController,
                      decoration: InputDecoration(
                        hintText: "Confirme sua nova senha",
                        hintStyle: const TextStyle(color: Colors.black45),
                        label: const Text(
                          "Confirmar Nova Senha",
                          style: TextStyle(color: Colors.black54),
                        ),
                        prefixIcon: const Icon(Icons.key_sharp),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlueAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: const BorderSide(
                            color: Colors.lightBlue,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Espaçamento antes dos botões
                    SizedBox(
                      width: double.infinity, // Preenche toda a largura disponível
                      child: ElevatedButton(
                        onPressed: () {
                          _atualizaSenha();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shadowColor: Colors.black,
                        ),
                        child: const Text(
                          "Salvar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _exibeEdit(BuildContext context, Widget x, Future<void> Function() y) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Define o tamanho mínimo
                      children: [
                        const Text(
                          "Insira seus novos dados:",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            fontFamily: 'Open Sans',
                            fontSize: 16,
                          ),
                        ),
                        x,
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity, // Preenche toda a largura disponível
                          child: ElevatedButton(
                            onPressed: () {
                              y();
                              Navigator.of(context).pop();
                              noRead = false;
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              shadowColor: Colors.black,
                            ),
                            child: const Text(
                              "Salvar",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    noRead = true;
  }

  Future<void> _recuperarToken() async {
    String? tokenRecuperado = await PSharedPreferences().getString("USUARIO"); // Pegue o token direto do SharedPreferences
    setState(() {
      token = tokenRecuperado;
    });
    print(token);
  }

  void _buscarEndereco() async {
    final cep = _cepController.text.replaceAll("-", "").trim(); // Remover traço antes de enviar
    if (cep.length == 8) {
      try {
        final endereco = await buscarEnderecoPorCep(cep);
        setState(() {
          _estadoController.text = endereco['uf'] ?? "";
          _cidadeController.text = endereco['localidade'] ?? "";
          _ruaController.text = endereco['logradouro'] ?? "";
          _bairroController.text = endereco['bairro'] ?? "";
          _complementoController.text = endereco['complemento'] ?? "";
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CEP inválido. Digite 8 números.")),
      );
    }
  }

  Future<Map<String, dynamic>> buscarEnderecoPorCep(String cep) async {
    try {
      final response = await Dio().get("https://viacep.com.br/ws/$cep/json/");
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['erro'] == true) {
          throw Exception("CEP inválido.");
        }
        return response.data;
      } else {
        throw Exception("Erro ao buscar o endereço.");
      }
    } catch (e) {
      throw Exception("Falha na conexão: $e");
    }
  }

  String _formatarTelefone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), ''); // Remove caracteres não numéricos
    if (digits.isEmpty) return ''; // Retorna vazio se não houver dígitos
    if (digits.length <= 2) return '($digits';
    if (digits.length <= 7) return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    if (digits.length <= 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}'; // Limita ao formato esperado
  }

  void _alertLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sair da conta?", //mudar para dinâmico
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Text("Você deseja realmente sair da sua conta?",
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Voltar",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
              child: const Text("Sim",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  /*Future<void> _recuperarDadosVoluntario() async {
    PSharedPreferences prefs = PSharedPreferences();
    List<dynamic> dados = await prefs.getJson(prefs.VOLUNTARIO);
    print(dados);
  }*/

}
