import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';

class Evento extends StatefulWidget {
  @override
  _EventoState createState() => _EventoState();
}

class _EventoState extends State<Evento> {
  String? _opcaoHabilidade;
  String? token;
  int idEvento = 0;
  int idHabilidade = 0;
  List<dynamic> _eventos = [];
  List<dynamic> _voluntario = [];
  bool _isLoading = true;

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isAscending = true;

  Future<void> _initialize() async {
    await _recuperarToken();
    _listagemEventos();
    await _recuperarDadosVoluntario();
  }

  Future<void> _listagemEventos() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaEvento',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      setState(() {
        _eventos = response.data['data'];
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar eventos: $e');
    }
  }

  Future<void> _inscreverEvento() async {
    if(validarVoluntarios(_voluntario) == false){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Os dados do perfil não foram todos preenchidos!'),
          backgroundColor: Colors.red,),
      );
    }
    else if(voluntarioTemHabilidade(_voluntario, _opcaoHabilidade) == false){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você não possui a habilidade selecionada!'),
          backgroundColor: Colors.red,),
      );
    }
    else{
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/inscrever',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'id_evento': idEvento,
            'id_habilidade': idHabilidade,
          },),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green,),
          );
          // Limpa as variáveis após a inscrição ser realizada
          setState(() {
            _opcaoHabilidade = null; // Limpa a habilidade selecionada
            idHabilidade = 0; // Limpa o ID da habilidade
            idEvento = 0; // Limpa o ID do evento
          });
          _listagemEventos();
        }
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível realizar a inscrição no evento!'),
            backgroundColor: Colors.red,),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _exibeInfo(BuildContext context, dynamic evento) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final habilidadeSelecionada = evento['habilidades']
            ?.firstWhere(
              (habilidade) =>
          habilidade['quantidade'] != null &&
              habilidade['meta'] != null &&
              habilidade['quantidade'] < habilidade['meta'],
          orElse: () => null,
        );
        if (habilidadeSelecionada != null) {
          _opcaoHabilidade = habilidadeSelecionada['descricao_habilidade']?.toString();
          idHabilidade = habilidadeSelecionada['id_habilidade'];
        }
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      Center(
                        child: Text(evento['nome_evento'],
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 5),
                      Center(
                        child: Text(evento['instituicao']['nome'],
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(),
                      SizedBox(height: 7),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            const Text("Dados da Instituição:",
                              style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                            ),
                            const SizedBox(height: 5,),
                            Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(width: 10,),
                                          Icon(Icons.phone_outlined, color: Colors.lightBlue,),
                                          SizedBox(width: 10,),
                                          Text(
                                            evento['instituicao']['telefone']?.isNotEmpty ?? false
                                                ? evento['instituicao']['telefone']
                                                : '(XX) XXXXX-XXXX',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                              fontFamily: 'Rubik',
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          // Verifica se o WhatsApp está disponível
                                          if (evento['instituicao']['whatsapp'] != null && evento['instituicao']['whatsapp'].isNotEmpty)
                                            Row(
                                              children: [
                                                SizedBox(width: 10,),
                                                Icon(Icons.phone_android_outlined, color: Colors.lightBlue,),
                                                SizedBox(width: 10,),
                                                Text(
                                                  evento['instituicao']['whatsapp'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                    color: Colors.black,
                                                    fontFamily: 'Rubik',
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 5,),
                                      Row(
                                        children: [
                                          SizedBox(width: 10,),
                                          Icon(Icons.mail_outline, color: Colors.lightBlue,),
                                          SizedBox(width: 10,),
                                          Text(evento['instituicao']['email'],
                                            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5,),
                                      Row(
                                        children: [
                                          SizedBox(width: 10,),
                                          Icon(Icons.navigation_outlined, color: Colors.lightBlue,),
                                          SizedBox(width: 10,),
                                          Expanded(child: Text(evento['instituicao']['endereco'].toString(),
                                            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                          ),)
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Text("Dados do evento:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 5,),
                      Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: BorderRadius.all(Radius.circular(15))),
                          child: Container(
                            padding: EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: 10,),
                                    Icon(Icons.date_range_outlined, color: Colors.lightBlue,),
                                    SizedBox(width: 10,),
                                    Text("Data: ${evento['data_evento']}",
                                      style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5,),
                                Row(
                                  children: [
                                    SizedBox(width: 10,),
                                    Icon(Icons.access_time_rounded, color: Colors.lightBlue,),
                                    SizedBox(width: 10,),
                                    Text("Horário: ${evento['hora_evento']}",
                                      style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5,),
                                Row(
                                  children: [
                                    SizedBox(width: 10,),
                                    Icon(Icons.place_outlined, color: Colors.lightBlue,),
                                    SizedBox(width: 10,),
                                    Expanded(child: Text(evento['instituicao']['endereco'],
                                      style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                    ),)
                                  ],
                                ),
                              ],
                            ),
                          )
                      ),
                      SizedBox(height: 15),
                      Text("Metas:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            SizedBox(height: 5),
                            Container(
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(evento['habilidades'].length, (index) {
                                    final habilidade = evento['habilidades'][index];
                                    final progress = habilidade['quantidade'] / habilidade['meta'];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${habilidade['descricao_habilidade']}:",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black,
                                            fontFamily: 'Open Sans',
                                            fontSize: 15,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                child: LinearProgressIndicator(
                                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                                  value: progress.clamp(0.0, 1.0),  // Evita valores acima de 1
                                                  minHeight: 10,
                                                  backgroundColor: Colors.grey[300],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "${habilidade['quantidade']}/${habilidade['meta']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                                fontFamily: 'Open Sans',
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),  // Espaço entre as habilidades
                                      ],
                                    );
                                  }),
                                ),
                            ),
                            SizedBox(height: 5,),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Text("Habilidades disponíveis:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            ...evento['habilidades']?.where((habilidade) {
                              return habilidade != null &&
                                  habilidade['quantidade'] != null &&
                                  habilidade['meta'] != null &&
                                  habilidade['quantidade'] < habilidade['meta'];
                            })?.map((habilidade) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                title: Text(habilidade['descricao_habilidade']),
                                leading: Radio<String>(
                                  activeColor: Colors.lightBlue,
                                  value: habilidade['descricao_habilidade'],  // Valor para a habilidade
                                  groupValue: _opcaoHabilidade,  // A habilidade selecionada
                                  onChanged: (String? value) {
                                    setState(() {
                                      idHabilidade= habilidade['id_habilidade'];
                                      _opcaoHabilidade = value!;  // Atualizando a habilidade selecionada
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      Text("Descrição:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Text(evento['descricao_evento'],
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Open Sans', fontSize: 15,height: 1.5,),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shadowColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exibeInfo3(context, evento);
                        },
                        child: Text('Quero participar',style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              );
            });
      },
    );
  }

  void _exibeInfo3(BuildContext context, dynamic evento) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Deseja participar do evento?", //mudar para dinâmico
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Text("Sua inscrição para ${_opcaoHabilidade ?? 'habilidade não selecionada'} será enviada com os dados cadastrados no aplicativo!!", //mudar para dinâmico
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exibeInfo(context, evento);
              },
              child: Text("Voltar",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  idEvento = evento['id_evento'];
                });
                _inscreverEvento();
                Navigator.of(context).pop();
              },
              child: Text("Sim", //mudar para dinâmico
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar por nome do evento ou nome da instituição
    List<dynamic> filteredEventos = _eventos.where((evento) {
      final nomeEvento = evento['nome_evento']?.toLowerCase() ?? '';
      final nomeInstituicao = evento['instituicao']?['nome']?.toLowerCase() ?? '';
      return nomeEvento.contains(searchQuery.toLowerCase()) ||
          nomeInstituicao.contains(searchQuery.toLowerCase());
    }).toList();

    // Ordenar a lista filtrada
    if (isAscending) {
      filteredEventos.sort((a, b) => a['nome_evento'].compareTo(b['nome_evento']));
    } else {
      filteredEventos.sort((a, b) => b['nome_evento'].compareTo(a['nome_evento']));
    }

    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(color: Colors.lightBlue),
          child: Column(
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
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
                    : filteredEventos.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy, // Ícone para eventos não encontrados
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Nenhum evento encontrado.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredEventos.length,
                  itemBuilder: (context, index) {
                    final evento = filteredEventos[index];
                    return InkWell(
                      onTap: () => _exibeInfo(context, evento),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: const Color(0xe3f4f4f5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 5, top: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Chip(
                                      shape: const RoundedRectangleBorder(
                                        side: BorderSide(
                                          style: BorderStyle.solid,
                                          color: Colors.transparent,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(30),
                                        ),
                                      ),
                                      label: Text(
                                        evento['data_evento'] ??
                                            'Data não disponível',
                                        textAlign: TextAlign.center,
                                      ),
                                      labelStyle: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                      backgroundColor:
                                      Colors.lightBlueAccent[100],
                                    ),
                                    const SizedBox(width: 10),
                                    Chip(
                                      shape: const RoundedRectangleBorder(
                                        side: BorderSide(
                                          style: BorderStyle.solid,
                                          color: Colors.transparent,
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(30),
                                        ),
                                      ),
                                      label: Text(
                                        evento['hora_evento'] ??
                                            'Horário não disponível',
                                        textAlign: TextAlign.center,
                                      ),
                                      labelStyle: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                      backgroundColor:
                                      Colors.lightBlueAccent[100],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  evento['nome_evento'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 25,
                                    fontFamily: 'Open Sans',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5, bottom: 5, top: 15),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.lightBlueAccent,
                                      radius: 20, // Define o tamanho do CircleAvatar
                                      child: evento['instituicao']?['profile_photo_url'] != null &&
                                          evento['instituicao']?['profile_photo_url'].isNotEmpty
                                          ? ClipOval(
                                        child: Image.network(
                                          evento['instituicao']?['profile_photo_url'],
                                          width: 40, // Dobre o valor do raio para garantir que preencha
                                          height: 40,
                                          fit: BoxFit.cover, // Garante que a imagem preencha o círculo
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.account_circle, size: 20, color: Colors.white);
                                          },
                                        ),
                                      )
                                          : const Icon(Icons.account_circle, size: 20, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        evento['instituicao']?['nome'] ?? 'Sem Instituição',
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _recuperarToken() async {
    String? tokenRecuperado = await PSharedPreferences().getString("USUARIO"); // Pegue o token direto do SharedPreferences
    setState(() {
      token = tokenRecuperado;
    });
  }

  Future<void> _recuperarDadosVoluntario() async {
    PSharedPreferences prefs = PSharedPreferences();
    _voluntario = await prefs.getJson(prefs.VOLUNTARIO);
  }

  bool validarVoluntarios(List<dynamic> voluntarios) {
    for (var voluntario in voluntarios) {
      if (voluntario is Map<String, dynamic>) {
        // Verificar endereço
        final endereco = voluntario['endereco'];
        if (endereco == null ||
            endereco['cep_endereco'] == null || endereco['cep_endereco'].isEmpty ||
            endereco['complemento_endereco'] == null || endereco['complemento_endereco'].isEmpty ||
            endereco['cidade_endereco'] == null || endereco['cidade_endereco'].isEmpty ||
            endereco['logradouro_endereco'] == null || endereco['logradouro_endereco'].isEmpty ||
            endereco['estado_endereco'] == null || endereco['estado_endereco'].isEmpty ||
            endereco['bairro_endereco'] == null || endereco['bairro_endereco'].isEmpty ||
            endereco['numero_endereco'] == null) {
          print('Voluntário com ID ${voluntario['id_voluntario']} possui endereço incompleto.');
          return false;
        }

        // Verificar contato
        final contato = voluntario['contato'];
        if (contato == null ||
            contato['telefone_contato'] == null || contato['telefone_contato'].isEmpty) {
          print('Voluntário com ID ${voluntario['id_voluntario']} não possui telefone de contato.');
          return false;
        }
      } else {
        print('Item inválido na lista: não é um mapa válido.');
        return false;
      }
    }
    return true; // Todos os voluntários estão válidos
  }

  bool voluntarioTemHabilidade(dynamic voluntario, String? opcaoHabilidade) {
    if (voluntario is List) {
      // Se voluntario for uma lista, verificar o primeiro elemento
      voluntario = voluntario.isNotEmpty ? voluntario.first : null;
    }
    if (voluntario is Map<String, dynamic>) {
      final habilidades = voluntario['habilidades'];
      if (habilidades is List<dynamic>) {
        for (var habilidade in habilidades) {
          if (habilidade is Map<String, dynamic> &&
              habilidade['descricao_habilidade'] == opcaoHabilidade) {
            return true;
          }
        }
      }
    }
    return false;
  }

}
