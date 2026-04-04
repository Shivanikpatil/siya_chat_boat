abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  String res;

  SearchLoaded({required this.res});
}

class SearchError extends SearchState {
  String errorMessage = "";

  SearchError({required this.errorMessage});
}
