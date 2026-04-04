import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;

import 'cubit_state.dart';

class SearchCubit extends Cubit<SearchState> {
  static List<Map<String, dynamic>> chatList = [];

  SearchCubit() : super(SearchInitial());
  // void getAIResponse({required String query}) async {
  //   emit(SearchLoading());
  //   try {
  //     String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";
  //     String APIKey = "AIzaSyAUKqjhOzMcTkDnkRXBz8O8tyahWAj0FXg";
  //     Map<String, dynamic> bodyPara = {
  //       "contents": [
  //         {
  //           "parts": [
  //             {"text": query},
  //           ],
  //         },
  //       ],
  //     };
  //     var response = await http.post(Uri.parse(url), body: jsonEncode(bodyPara), headers: {"x-goog-api-key": APIKey, "Content-Type": "application/json"});
  //     if (response.statusCode == 200) {
  //       print(response.body);
  //       var Data = jsonDecode(response.body);
  //       var resp = Data['candidates'][0]["content"]["parts"][0]["text"];
  //       emit(SearchLoaded(res: resp));
  //     } else {
  //       emit(SearchError(errorMessage: e.toString()));
  //
  //       print(response.statusCode);
  //     }
  //   } on Exception catch (e) {
  //     emit(SearchError(errorMessage: e.toString()));
  //
  //     print(e);
  //   }
  // }
  void getAIResponse({required String query}) async {
    emit(SearchLoading());

    chatList.add({
      "role": "user",
      "parts": [
        {"text": query},
      ],
    });

    try {
      String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";
      String APIKey = "AIzaSyC-UxiWfVayZvZCU3bE02wbtsHxKZAkFdE";
      // String APIKey = "AIzaSyAUKqjhOzMcTkDnkRXBz8O8tyahWAj0FXg";
      Map<String, dynamic> bodyPara = {"contents": chatList};
      var response = await http.post(Uri.parse(url), body: jsonEncode(bodyPara), headers: {"x-goog-api-key": APIKey, "Content-Type": "application/json"});
      if (response.statusCode == 200) {
        print(response.body);
        var Data = jsonDecode(response.body);
        var resp = Data['candidates'][0]["content"]["parts"][0]["text"];
        chatList.add({
          "role": "model",
          "parts": [
            {"text": resp},
          ],
        });
        emit(SearchLoaded(res: resp));
      } else if(response.statusCode == 429){
        emit(SearchError(errorMessage: "429"));

        print(response.statusCode);
      }else {
        emit(SearchError(errorMessage: e.toString()));

        print(response.statusCode);
      }
    } on Exception catch (e) {
      emit(SearchError(errorMessage: e.toString()));

      print(e);
    }
  }
}
