enum SearchResultType {
  alcohol,
  profile,
}

class SearchResultModel {
  final SearchResultType type;
  final dynamic data;

  SearchResultModel({
    required this.type,
    required this.data,
  });
}
