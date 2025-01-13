import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maos_solidarias_dm/screens/busca_instituicao.dart';
import 'package:maos_solidarias_dm/screens/doacao.dart';
import 'package:maos_solidarias_dm/screens/evento.dart';
import 'package:maos_solidarias_dm/screens/perfil.dart';

class Navegar extends StatefulWidget {
  @override
  _NavegarState createState() => _NavegarState();
}

class _NavegarState extends State<Navegar> {
  int currentPageIndex = 0;
  NavigationDestinationLabelBehavior labelBehavior =
      NavigationDestinationLabelBehavior.onlyShowSelected;

  List<Widget> _screens = <Widget>[
    Doacao(),
    Evento(),
    Busca(),
    Perfil()
  ];

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
    // Set the initial page based on arguments if available
    Future.delayed(Duration.zero, () {
      final int? initialPageIndex = ModalRoute.of(context)?.settings.arguments as int?;
      if (initialPageIndex != null) {
        setState(() {
          currentPageIndex = initialPageIndex;
        });
      }
    });
  }

  Future _onSair() {
    Future resp = showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Sair do aplicativo'),
        content: new Text('Deseja realmente sair do App?', style: TextStyle(fontSize: 15),),
        actions: [
          new TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('Não', style: TextStyle(color: Colors.lightBlue, fontSize: 17),),
          ),
          new TextButton(
            onPressed: () {
              exit(0);
            },
            child: new Text('Sim', style: TextStyle(color: Colors.lightBlue, fontSize: 17),),
          ),
        ],
      ),
    );
    if (resp == null || resp == false){
      return retorno(false);
    }else{
      return retorno(true);
    }
  }

  Future retorno(bool x) async{
    if (x){
      return true;
    }else
      return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            title: null,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.lightBlue,
            toolbarHeight: 0,
          ),
          body: _screens.elementAt(
            currentPageIndex,
          ),
          bottomNavigationBar: NavigationBar(
            height: 60,
            labelBehavior: labelBehavior,
            selectedIndex: currentPageIndex,
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            indicatorColor: Colors.black12,
            backgroundColor: Colors.grey[100],
            destinations: const <Widget>[
              NavigationDestination(
                selectedIcon: Icon(Icons.handshake_rounded,color: Colors.black87,),
                icon: Icon(Icons.handshake_outlined,color: Colors.black54,),
                label: 'Doação',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.event_rounded,color: Colors.black87,),
                icon: Icon(Icons.event_outlined,color: Colors.black54,),
                label: 'Evento',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.search_rounded,color: Colors.black87,),
                icon: Icon(Icons.search_outlined,color: Colors.black54,),
                label: 'Busca',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.portrait_rounded,color: Colors.black87,),
                icon: Icon(Icons.portrait_outlined, color: Colors.black54,),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      canPop: false,
      onPopInvoked: (didPop) {
        if(didPop){
          return;
        }
        _onSair();
      }
    );
  }
}


