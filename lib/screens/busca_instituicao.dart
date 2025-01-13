import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';
import 'package:maos_solidarias_dm/screens/instituicao.dart';

class Busca extends StatefulWidget {
  @override
  _BuscaState createState() => _BuscaState();
}

class _BuscaState extends State<Busca> {
  bool isAscending = true;
  bool _clicou = false;
  String? token;
  List<dynamic> _instituicoes = [];
  dynamic instituicaoSelecionada;
  bool _isLoading = true;

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<void> _initialize() async {
    await _recuperarToken();
    _listagemEventos();
  }

  Future<void> _listagemEventos() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaInstituicao',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      setState(() {
        _instituicoes = response.data['data'];
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar instituições: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return _clicou ? Instituicao(instituicao: instituicaoSelecionada) : _buildInitialLayout();
  }

  Widget _buildInitialLayout() {
    // Filtrar por nome da instituição
    List<dynamic> filteredInstituicoes = _instituicoes.where((instituicao) {
      final nomeInstituicao = instituicao['nome']?.toLowerCase() ?? '';
      return nomeInstituicao.contains(searchQuery.toLowerCase());
    }).toList();

    // Ordenar a lista filtrada
    if (isAscending) {
      filteredInstituicoes.sort((a, b) => a['nome'].compareTo(b['nome']));
    } else {
      filteredInstituicoes.sort((a, b) => b['nome'].compareTo(a['nome']));
    }

    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Colors.lightBlue),
          child: ListView(
            children: [
              // Campo de pesquisa
              Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 9,
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white70),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          filled: false,
                          contentPadding: const EdgeInsets.all(10),
                          hintText: "Digite...",
                          hintStyle: const TextStyle(color: Colors.white70),
                          label: const Text(
                            "Pesquisa",
                            style: TextStyle(color: Colors.white70),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.white70,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(
                          isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isAscending = !isAscending;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de Instituições ou mensagem de "nenhum dado encontrado"
              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
                  : filteredInstituicoes.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Nenhuma instituição encontrada.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredInstituicoes.length,
                itemBuilder: (context, index) {
                  var instituicao = filteredInstituicoes[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        instituicaoSelecionada = instituicao;
                        _clicou = true;
                      });
                    },
                    child: Card(
                      color: const Color(0xe3f4f4f5),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.lightBlueAccent,
                              child: Image.asset(
                                'img/user.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              child: Text(
                                instituicao['nome'] ?? 'Sem nome',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xed171718),
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _recuperarToken() async {
    String? tokenRecuperado = await PSharedPreferences().getString("USUARIO");
    setState(() {
      token = tokenRecuperado;
    });
  }
}
