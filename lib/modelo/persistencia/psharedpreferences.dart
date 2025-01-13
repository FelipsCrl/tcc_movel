import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PSharedPreferences {
  final String USUARIO = "USUARIO";
  final String VOLUNTARIO = "VOLUNTARIO";

  Future<bool> getBoolean(String OPCAO) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(OPCAO) ?? false);
  }

  Future<String> getString(String OPCAO) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getString(OPCAO) ?? "");
  }

  Future<void> setBoolean(String OPCAO, value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OPCAO, value);
  }

  Future<void> setString(String OPCAO, value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(OPCAO, value);
  }

  // Método para salvar um JSON como string
  Future<void> setJson(String key, List<dynamic> json) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(json);
    await prefs.setString(key, jsonString);
  }

  // Método para recuperar um JSON como objeto
  Future<List<dynamic>> getJson(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return [];
  }

  // Método para remover dados de uma chave
  Future<void> remove(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Método para limpar todos os dados salvos
  Future<void> clearAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
