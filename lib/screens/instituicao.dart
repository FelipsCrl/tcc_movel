import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:maos_solidarias_dm/modelo/persistencia/psharedpreferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Instituicao extends StatefulWidget {
  final Map<String, dynamic> instituicao;

  // Construtor que recebe os dados da instituição
  Instituicao({required this.instituicao});

  @override
  _InstituicaoState createState() => _InstituicaoState();
}

class _InstituicaoState extends State<Instituicao> {
  TextEditingController _quantidade = TextEditingController();
  TextEditingController _tipoDoacao = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _formattedDateTime = "";
  String _opcao = "cadastrado";
  String? token;
  dynamic instituicaoSelecionada;
  List<dynamic> _habilidades = [];
  List<dynamic> _voluntario = [];
  int idHabilidade = 0;
  String? _opcaoDoacao = 'Levar'; //se vai levar ou buscar a doação
  String? _opcaoHabilidade;

  int currentPageIndex = 0;

  Widget _selectePage(){
    if(currentPageIndex == 0) {
      return _dataPage(instituicaoSelecionada);
    }
    else if(currentPageIndex == 1) {
      return _transparenciaPage(instituicaoSelecionada);
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

  final _formKey = GlobalKey<FormState>();
  String? _selectedValue;

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

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível realizar a ação!'),backgroundColor: Colors.red,),
      );
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _inscrever() async {
    print(_voluntario);
    print(_opcaoHabilidade);
    if(validarVoluntarios(_voluntario) == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Os dados do perfil não foram todos preenchidos!'),backgroundColor: Colors.red,),
      );
    }
    else if (voluntarioTemHabilidade(_voluntario[0], _opcaoHabilidade) == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você não possui a habilidade selecionada!'),
          backgroundColor: Colors.red,
        ),
      );
    }
    else {
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/voluntariar',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'id_instituicao': instituicaoSelecionada["id_instituicao"],
            'id_habilidade': idHabilidade,
          },),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green,),
          );

          // Limpa as variáveis após a doação ser realizada
          setState(() {
            _selectedValue = null;
          });
        }
      } on DioException catch (e) {
        if(e.response?.statusCode == 422){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.response?.data['message'])),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível realizar a inscrição!'),backgroundColor: Colors.red,),
          );
          print('Erro ao se voluntariar: $e');
        }
      }
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

  Future<void> _doarAgora() async {
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
    else if(_tipoDoacao.text == ''){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoria da doação não inserida!'),backgroundColor: Colors.red,),
      );
    }
    else {
      try {
        final Dio _dio = Dio();
        Response response = await _dio.post(
          'http://127.0.0.1:8000/api/doarAgora',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
          data: FormData.fromMap({
            'id_instituicao': instituicaoSelecionada["id_instituicao"],
            'categoria': _tipoDoacao.text,
            'quantidade_doacao': _quantidade.text,
            'data_hora_coleta': _opcaoDoacao == 'Recolher'
                ? _formattedDateTime
                : null,
          },),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message']), backgroundColor: Colors.green,),
          );

          // Limpa as variáveis após a doação ser realizada
          setState(() {
            _tipoDoacao.clear();
            _quantidade.clear(); // Limpa o campo de quantidade
            _selectedDate = null; // Limpa a data da coleta
            _selectedTime = null; // Limpa o horário da coleta
            _formattedDateTime = ""; // Limpa a data e horário da coleta
          });

        }
      } on DioException catch (e) {
        if(e.response?.statusCode == 422){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.response?.data['message'])),
          );
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível realizar a doação!'),backgroundColor: Colors.red,),
          );
          print('Erro ao realizar doação: $e');
        }
      }
    }
  }

  Future<void> _initialize() async {
    await _recuperarToken();
    _listagemHabilidades();
    await _recuperarDadosVoluntario();
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = ""; // Inicializa vazio
    _timeController.text = ""; // Inicializa vazio
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final dynamic instituicao = widget.instituicao;
    instituicaoSelecionada = instituicao;
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_outlined, color: Colors.white,size: 30,),
              onPressed: () {
                Navigator.pushNamed(context, '/navegar', arguments: 2);
              },
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ElevatedButton(
              onPressed: (){
                _voluntariar(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.black,
              ),
              child: const Text("Voluntariar",style: TextStyle(color: Colors.lightBlueAccent),),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ElevatedButton(
              onPressed: (){
                _doar(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.black,
              ),
              child: const Text("Doar",style: TextStyle(color: Colors.lightBlueAccent),),
            ),
          )
        ],
        automaticallyImplyLeading: false,
        backgroundColor: Colors.lightBlue,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: Colors.lightBlue),
        child: Column(
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height/3,
                decoration: const BoxDecoration(
                  color: Colors.lightBlue,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 65.0,
                      backgroundColor: Colors.white,
                      child: Image.asset('img/user.png',color: Colors.black,),
                    ),
                    Text(instituicao['nome'],
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white,fontFamily: 'Rubik', fontSize: 20),),
                  ],
                )
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                      child: InkWell(
                        child: Container(
                          width: MediaQuery.of(context).size.width/2,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _containerColors[0]
                          ),
                          child: const Text('Dados',
                            style: TextStyle(fontWeight: FontWeight.w400, color: Colors.black,fontFamily: 'Open Sans',),),
                        ),
                        onTap: (){
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
                        width: MediaQuery.of(context).size.width/2,
                        height: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _containerColors[1],
                        ),
                        child: const Text('Transparência',
                          style: TextStyle(fontWeight: FontWeight.w400, color: Colors.black,fontFamily: 'Open Sans',),),
                      ),
                      onTap: (){
                        setState(() {
                          currentPageIndex = 1;
                        });
                        _changeColor(1);
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
    );
  }
  Widget _dataPage(dynamic instituicao){
    return(
        Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.white),
              child: ListView(
                children: [
                  Container(padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Sobre:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                          width: MediaQuery.of(context).size.width,
                          child: Text(instituicao['descricao'],
                            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Open Sans', fontSize: 15,height: 1.5,),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Endereço:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
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
                                      Icon(Icons.place_outlined, color: Colors.lightBlue,),
                                      SizedBox(width: 10,),
                                      Expanded(child: Text(instituicao['endereco'],
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
                  Container(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Contato:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
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
                                      SizedBox(width: 5,),
                                      Icon(Icons.phone_outlined, color: Colors.lightBlue,),
                                      SizedBox(width: 5,),
                                      Text(
                                        instituicao['telefone']?.isNotEmpty ?? false
                                            ? instituicao['telefone']
                                            : '(XX) XXXXX-XXXX',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                          fontFamily: 'Rubik',
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 5,),
                                      // Verifica se o WhatsApp está disponível
                                      if (instituicao['whatsapp'] != null && instituicao['whatsapp'].isNotEmpty)
                                        Row(
                                          children: [
                                            SizedBox(width: 10,),
                                            Icon(Icons.phone_android_outlined, color: Colors.lightBlue,),
                                            SizedBox(width: 10,),
                                            Text(
                                              instituicao['whatsapp'],
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
                                      Text(instituicao['email'],
                                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
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
                        const Text("Funcionamento:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 5,),
                        Container(
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey,style: BorderStyle.solid),borderRadius: const BorderRadius.all(Radius.circular(15))),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              child: Column(
                                children: [
                                  SizedBox(height: 5,),
                                  Row(
                                    children: [
                                      Center(child: Icon(Icons.date_range_outlined, color: Colors.lightBlue,),),
                                      SizedBox(width: 10,),
                                      Text(instituicao['funcionamento_instituicao']['horario'],
                                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
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
                        const Text("Redes Sociais:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 5,),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              children: [
                                if (instituicao['whatsapp'] != null && instituicao['whatsapp'].isNotEmpty)
                                  Expanded(
                                    child: IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.whatsapp),
                                      onPressed: () {
                                        String cleanNumber = instituicao['whatsapp'].replaceAll(RegExp(r'[^\d]'), '');
                                        if (!cleanNumber.startsWith('55')) {
                                          cleanNumber = '55$cleanNumber';
                                        }
                                        _launchUrl(Uri.parse('https://wa.me/$cleanNumber'));
                                      },
                                    ),
                                  ),
                                if (instituicao['instagram'] != null && instituicao['instagram'].isNotEmpty)
                                  Expanded(
                                    child: IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.instagram),
                                      onPressed: () {
                                        _launchUrl(Uri.parse(instituicao['instagram']));
                                      },
                                    ),
                                  ),
                                if (instituicao['facebook'] != null && instituicao['facebook'].isNotEmpty)
                                  Expanded(
                                    child: IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.facebook),
                                      onPressed: () {
                                        _launchUrl(Uri.parse(instituicao['facebook']));
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }

  Widget _transparenciaPage(dynamic instituicao){
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
                        const Text("Site institucional:",
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black,fontFamily: 'Rubik', fontSize: 19),
                          textAlign: TextAlign.left,
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
                                      Icon(Icons.factory_outlined, color: Colors.lightBlue,),
                                      SizedBox(width: 10,),
                                      Expanded(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click, // Cursor de "mãozinha"
                                            child: GestureDetector(
                                              onTap: () => _launchUrl(Uri.parse(instituicao['site']!)),
                                              child: Text(
                                                instituicao['site']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.blue, // Indica que é um link
                                                  fontFamily: 'Rubik',
                                                  fontSize: 14,
                                                  decoration: TextDecoration.underline, // Estilo de link
                                                  decorationColor: Colors.blue
                                                ),
                                              ),
                                            ),
                                          ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }

  void _voluntariar(BuildContext context) {
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
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Selecione a habilidade referente:",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            fontFamily: 'Rubik',
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.lightBlueAccent,
                                        width: 2.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.lightBlue,
                                        width: 2.0,
                                      ),
                                    ),
                                    labelText: 'Habilidade',
                                    labelStyle: const TextStyle(color: Colors.black87),
                                    border: const OutlineInputBorder(),
                                  ),
                                  value: _selectedValue,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedValue = newValue;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Selecione uma habilidade' : null,
                                  items: _habilidades.map<DropdownMenuItem<String>>((habilidade) {
                                    return DropdownMenuItem<String>(
                                      value: habilidade['id_habilidade'].toString(),
                                      child: Text(habilidade['descricao_habilidade'],
                                          style: const TextStyle(color: Colors.black87)),
                                      onTap: (){
                                        idHabilidade = habilidade['id_habilidade'];
                                        _opcaoHabilidade = habilidade['descricao_habilidade'];
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              shadowColor: Colors.black,
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.of(context).pop();
                                _alertVoluntario(context);
                              }
                            },
                            child: const Text(
                              'Enviar solicitação',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
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
  }


  void _doar(BuildContext context) {
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
                      const SizedBox(height: 5),
                      const Text("Como deseja realizar a doação:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
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
                              leading: Radio (
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
                            ListTile(
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Recolher em minha casa"),
                              leading: Radio (
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
                      _buildContainer(_opcaoDoacao!),
                      const SizedBox(height: 10),
                      const Text("Tipo de Doação:",
                        style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 18),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        cursorColor: Colors.black45,
                        controller: _tipoDoacao,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(10),
                          hintText: "ex: Roupa, Alimento,...",
                          hintStyle: const TextStyle(color: Colors.black45),
                          label: const Text("Doação", style: TextStyle(color: Colors.black54)),
                          prefixIcon: const Icon(
                            Icons.shopping_bag_outlined,
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
                          _alertDoador(context);
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

  Widget _buildContainer(String op) {
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
                      instituicaoSelecionada['telefone'] != null && instituicaoSelecionada['telefone'].isNotEmpty
                          ? instituicaoSelecionada['telefone']
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
                    if (instituicaoSelecionada['whatsapp'] != null && instituicaoSelecionada['whatsapp'].isNotEmpty)
                      Row(
                        children: [
                          SizedBox(width: 10,),
                          Icon(Icons.phone_android_outlined, color: Colors.lightBlue,),
                          SizedBox(width: 10,),
                          Text(
                            instituicaoSelecionada['whatsapp'],
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
                    Text(instituicaoSelecionada['email'],
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
                    Expanded(child: Text(instituicaoSelecionada['endereco'].toString(),
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
                    Text(instituicaoSelecionada['funcionamento_instituicao']['horario'],
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

  void _alertVoluntario(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Deseja realmente enviar a solicitação de voluntariado?",
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: const Text("Seus dados cadastrados no aplicativo serão enviados para a Instituição!",
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _voluntariar(context);
              },
              child: Text("Voltar",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                _inscrever();
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

  void _alertDoador(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Deseja realmente enviar a solicitação de doação?",
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          content: Text("${_quantidade.text == '' ? 'Quantidade não informada' : _quantidade.text} ${_tipoDoacao.text == '' ? 'e categoria não selecionada' : _tipoDoacao.text}, " +
              (_opcaoDoacao == 'Levar'
                  ? 'que será levada até o local.'
                  : 'que será coletada no seu endereço, na data e hora selecionados.'),
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black,fontFamily: 'Rubik', fontSize: 15),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _doar(context);
              },
              child: Text("Voltar",
                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.lightBlue,fontFamily: 'Rubik', fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                _doarAgora();
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
  Future<void> _recuperarToken() async {
    String? tokenRecuperado = await PSharedPreferences().getString("USUARIO"); // Pegue o token direto do SharedPreferences
    setState(() {
      token = tokenRecuperado;
    });
    print(token);
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
