import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';

class Doacao extends StatefulWidget {
  @override
  _DoacaoState createState() => _DoacaoState();
}

class _DoacaoState extends State<Doacao> {
  TextEditingController _quantidade = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _formattedDateTime = "";
  String? _opcaoCategoria; //qual categoria da doação
  String? _opcaoDoacao = 'Levar'; //se vai levar ou buscar a doação
  int idDoacao = 0;
  int idCategoria = 0;
  String? token;
  List<dynamic> _doacoes = [];
  List<dynamic> _voluntario = [];
  bool _isLoading = true;

  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isAscending = true;

  Future<void> _initialize() async {
    await _recuperarToken();
    _listagemDoacoes();
    await _recuperarDadosVoluntario();
  }

  Future<void> _listagemDoacoes() async {
    try {
      final Dio _dio = Dio();
      final response = await _dio.get('http://127.0.0.1:8000/api/listaDoacao',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      setState(() {
        _doacoes = response.data['data'];
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível buscar no sistema!'),backgroundColor: Colors.red,),
      );
      print('Erro ao buscar doações: $e');
    }
  }

  Future<void> _fazerDoacao() async {
    if(_quantidade.text == ''){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantidade não foi inserida!'),backgroundColor: Colors.red,),
      );
    }
    else if((_opcaoDoacao == 'Recolher') && (_selectedDate == null) && (_selectedTime == null)){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi definido o dia e horário para recolhimento da doação!'),backgroundColor: Colors.red,),
      );
    }
    else if(validarVoluntarios(_voluntario) == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Os dados do perfil não foram todos preenchidos!'),backgroundColor: Colors.red,),
      );
    }
    else {
        try {
          final Dio _dio = Dio();
          Response response = await _dio.post(
            'http://127.0.0.1:8000/api/doar',
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
              },
            ),
            data: FormData.fromMap({
              'id_doacao': idDoacao,
              'id_categoria': idCategoria,
              'quantidade_doacao': _quantidade.text,
              'data_hora_coleta': _opcaoDoacao == 'Recolher'
                  ? _formattedDateTime
                  : null,
            },),
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['message']),
                backgroundColor: Colors.green,),
            );

            // Limpa as variáveis após a doação ser realizada
            setState(() {
              _opcaoCategoria = null; // Limpa a categoria selecionada
              idCategoria = 0; // Limpa o ID da categoria
              idDoacao = 0; // Limpa o ID da doação
              _quantidade.clear(); // Limpa o campo de quantidade
              _selectedDate = null; // Limpa a data da coleta
              _selectedTime = null; // Limpa o horário da coleta
              _formattedDateTime = ""; // Limpa a data e horário da coleta
            });

            _listagemDoacoes();
          }
        } on DioException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível realizar a doação!'),backgroundColor: Colors.red,),
          );
          print('Erro ao se conectar à API: $e');
        }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue, // Cor principal do cabeçalho e seleção
              onPrimary: Colors.white,  // Cor do texto do cabeçalho
              onSurface: Colors.black87, // Cor do texto geral
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlue, // Cor dos botões (Hoje, Cancelar)
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text =
        "${_pad(_selectedDate!.day)}/${_pad(_selectedDate!.month)}/${_selectedDate!.year}";
        _updateFormattedDateTime();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue, // Cor principal do cabeçalho e seleção
              onPrimary: Colors.white,  // Cor do texto do cabeçalho
              onSurface: Colors.black87, // Cor do texto geral
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlue, // Cor dos botões
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text =
        "${_pad(_selectedTime!.hour)}:${_pad(_selectedTime!.minute)}";
        _updateFormattedDateTime();
      });
    }
  }

  /// Atualiza a string formatada de data e hora
  void _updateFormattedDateTime() {
    if (_selectedDate != null && _selectedTime != null) {
      final formattedDateTime = "${_selectedDate!.year}/${_pad(_selectedDate!.month)}/${_pad(_selectedDate!.day)} "
          "${_pad(_selectedTime!.hour)}:${_pad(_selectedTime!.minute)}";
      print("Data e Hora formatadas: $formattedDateTime");
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _exibeInfo(BuildContext context, dynamic doacao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        _opcaoCategoria = doacao['categorias']
            .firstWhere(
              (categoria) =>
          categoria['quantidade'] != null &&
              categoria['meta'] != null &&
              categoria['quantidade'] < categoria['meta'],
          orElse: () => null, // Caso nenhuma categoria satisfaça a condição
        )?['descricao_categoria']?.toString();

        idCategoria = doacao['categorias']
            .firstWhere(
              (categoria) =>
          categoria['quantidade'] != null &&
              categoria['meta'] != null &&
              categoria['quantidade'] < categoria['meta'],
          orElse: () => null,
        )?['id_categoria'];
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                       Center(
                        child: Text(doacao['nome_doacao'],
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(doacao['instituicao']['nome'],
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Divider(),
                      const SizedBox(height: 7),
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
                                            doacao['instituicao']['telefone'] != null && doacao['instituicao']['telefone'].isNotEmpty
                                                ? doacao['instituicao']['telefone']
                                                : '(XX) XXXXX-XXXX', // Valor padrão caso não tenha telefone
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                              fontFamily: 'Rubik',
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          // Verifica se o WhatsApp está disponível
                                          if (doacao['instituicao']['whatsapp'] != null && doacao['instituicao']['whatsapp'].isNotEmpty)
                                            Row(
                                              children: [
                                                SizedBox(width: 10,),
                                                Icon(Icons.phone_android_outlined, color: Colors.lightBlue,),
                                                SizedBox(width: 10,),
                                                Text(
                                                  doacao['instituicao']['whatsapp'],
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
                                          Text(doacao['instituicao']['email'],
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
                                          Expanded(child: Text(doacao['instituicao']['endereco'].toString(),
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
                      const SizedBox(height: 15),
                      const Text("Metas:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            Container(
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(doacao['categorias'].length, (index) {
                                    final categoria = doacao['categorias'][index];
                                    final progress = categoria['quantidade'] / categoria['meta'];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${categoria['descricao_categoria']}:",
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
                                              "${categoria['quantidade']}/${categoria['meta']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                                fontFamily: 'Open Sans',
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),  // Espaço entre as categorias
                                      ],
                                    );
                                  }),
                                ),
                            ),
                            const SizedBox(height: 5,),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("Observação:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Text(doacao['observacao_doacao'] ?? 'Não tem observação',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Open Sans', fontSize: 15,height: 1.5,),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text("Doações disponíveis:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            const SizedBox(height: 5),
                            // Listando categorias que não atingiram a meta
                            ...doacao['categorias']!.where((categoria) {
                              // Garantir que 'quantidade' e 'meta' são valores válidos
                              return categoria['quantidade'] != null && categoria['meta'] != null && categoria['quantidade'] < categoria['meta'];
                            }).map((categoria) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                title: Text(categoria['descricao_categoria']),
                                leading: Radio<String>(
                                  activeColor: Colors.lightBlue,
                                  value: categoria['descricao_categoria'],  // Valor para a categoria
                                  groupValue: _opcaoCategoria,  // A categoria selecionada
                                  onChanged: (String? value) {
                                    setState(() {
                                      idCategoria = categoria['id_categoria'];
                                      _opcaoCategoria = value!;  // Atualizando a categoria selecionada
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shadowColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exibeInfo2(context, doacao);
                        },
                        child: const Text('Quero doar',style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              );
            }
            );
      },
    );
  }

  void _exibeInfo2(BuildContext context, dynamic doacao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 5),
                  child: ListView(
                    children: [
                      Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_outlined, color: Colors.lightBlue,),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _exibeInfo(context, doacao);
                            },
                          ),
                        ],
                      ),
                      const Text("Como deseja realizar a doação:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              title: const Text("Levar ao local"),
                              leading: Radio(
                                activeColor: Colors.lightBlue,
                                value: "Levar",
                                groupValue: _opcaoDoacao,
                                onChanged: (String? value) {
                                  setState(() {
                                    _opcaoDoacao = value!;
                                  });
                                },
                              ),
                            ),
                            if (doacao['coleta_doacao'] == 1) // Verifica se coleta_doacao é igual a 1
                              ListTile(
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Recolher em minha casa"),
                                leading: Radio(
                                  activeColor: Colors.lightBlue,
                                  value: "Recolher",
                                  groupValue: _opcaoDoacao,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _opcaoDoacao = value!;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildContainer(_opcaoDoacao!, doacao),
                      const SizedBox(height: 10),
                      const Text("Quantidade:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.black45,
                        controller: _quantidade,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(10),
                          hintText: "Digite...",
                          hintStyle: const TextStyle(color: Colors.black45),
                          label: const Text("Quantidade", style: TextStyle(color: Colors.black54)),
                          prefixIcon: const Icon(
                            Icons.production_quantity_limits_outlined,
                            color: Colors.lightBlue,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.lightBlueAccent,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.lightBlue,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          shadowColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exibeInfo3(context, doacao);
                          },
                        child: const Text('Doar',style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              );
            }
            );
      },
    );
  }

  Widget _buildContainer(String op, dynamic doacao) {
    Widget _containerOpcao = Container();
      if(op == 'Levar')
        _containerOpcao = Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
            child: Container(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Text("Dados do local de entrega:", //mudar para dinâmico
                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 5,),
                  Row(
                    children: [
                      SizedBox(width: 10,),
                      Icon(Icons.phone_outlined, color: Colors.lightBlue,),
                      SizedBox(width: 10,),
                      Text(
                        doacao['instituicao']['telefone'] != null && doacao['instituicao']['telefone'].isNotEmpty
                            ? doacao['instituicao']['telefone']
                            : '(XX) XXXXX-XXXX', // Valor padrão caso não tenha telefone
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontFamily: 'Rubik',
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 10,),
                      // Verifica se o WhatsApp está disponível
                      if (doacao['instituicao']['whatsapp'] != null && doacao['instituicao']['whatsapp'].isNotEmpty)
                        Row(
                          children: [
                            SizedBox(width: 10,),
                            Icon(Icons.phone_android_outlined, color: Colors.lightBlue,),
                            SizedBox(width: 10,),
                            Text(
                              doacao['instituicao']['whatsapp'],
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
                      Text(doacao['instituicao']['email'],
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
                      Expanded(child: Text(doacao['instituicao']['endereco'].toString(),
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                      ),)
                    ],
                  ),
                  SizedBox(height: 5,),
                  Row(
                    children: [
                      SizedBox(width: 10,),
                      Icon(Icons.date_range_outlined, color: Colors.lightBlue,),
                      SizedBox(width: 10,),
                      Text(doacao['instituicao']['funcionamento_instituicao']['horario'],
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            )
        );
    else if(op == 'Recolher')
        _containerOpcao = SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
            ),
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                const Text(
                  "Insira a data e horário para recolhida",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    fontFamily: 'Rubik',
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  onTap: _selectDate,
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Data",
                    hintText: "Selecione uma data",
                    prefixIcon: const Icon(Icons.date_range_outlined, color: Colors.lightBlue),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  onTap: _selectTime,
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: "Horário",
                    hintText: "Selecione um horário",
                    prefixIcon: const Icon(Icons.access_time_outlined, color: Colors.lightBlue),
                  ),
                ),
              ],
            ),
          ),
        );
    return _containerOpcao;
  }

  void _exibeInfo3(BuildContext context, dynamic doacao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Deseja realizar a doação?", //mudar para dinâmico
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Text("A doação: ${_quantidade.text ?? 'quantidade não informada'} ${_opcaoCategoria ?? 'categoria não selecionada'}, " +
              (_opcaoDoacao == 'Levar'
                  ? 'será levada até o local.'
                  : 'será coletada no seu endereço, na data e hora selecionados.'),
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exibeInfo2(context, doacao);
              },
              child: const Text("Voltar",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  idDoacao = doacao['id_doacao'];
                });
                _fazerDoacao();
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

  @override
  Widget build(BuildContext context) {
    // Filtrar por nome da doação ou nome da instituição
    List<dynamic> filteredDoacoes = _doacoes.where((doacao) {
      final nomeDoacao = doacao['nome_doacao']?.toLowerCase() ?? '';
      final nomeInstituicao = doacao['instituicao']?['nome']?.toLowerCase() ?? '';
      return nomeDoacao.contains(searchQuery.toLowerCase()) ||
          nomeInstituicao.contains(searchQuery.toLowerCase());
    }).toList();

    // Ordenar a lista filtrada
    if (isAscending) {
      filteredDoacoes.sort((a, b) => a['nome_doacao'].compareTo(b['nome_doacao']));
    } else {
      filteredDoacoes.sort((a, b) => b['nome_doacao'].compareTo(a['nome_doacao']));
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
                          fillColor: Colors.white60,
                          contentPadding: const EdgeInsets.all(10),
                          hintText: "Digite...",
                          hintStyle: const TextStyle(color: Colors.white70),
                          label: const Text("Pesquisa", style: TextStyle(color: Colors.white70)),
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
              // Lista de doações ou mensagem de vazio
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : filteredDoacoes.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off, // Ícone de pesquisa sem resultados
                        size: 80,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Nenhum dado encontrado.",
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
                  itemCount: filteredDoacoes.length,
                  itemBuilder: (context, index) {
                    final doacao = filteredDoacoes[index];
                    return InkWell(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Card(
                          color: const Color(0xe3f4f4f5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: Text(
                                  doacao['nome_doacao'] ?? 'Sem Nome',
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
                                      child: Image.asset(
                                        'img/user.png',
                                        fit: BoxFit.contain,
                                      ),
                                      backgroundColor: Colors.lightBlueAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        doacao['instituicao']?['nome'] ?? 'Sem Instituição',
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
                      onTap: () {
                        _exibeInfo(context, doacao);
                      },
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
    print(tokenRecuperado);
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



}
