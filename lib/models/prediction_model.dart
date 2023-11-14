class PredictionModel {
  String? place_id;
  String? main_text;
  String? Secondary_text;

  PredictionModel({this.place_id, this.main_text, this.Secondary_text});

  PredictionModel.fromJson(Map<String, dynamic> json) {
    place_id = json['place_id'];
    main_text = json['structured_formatting']['main_text'];
    Secondary_text=json['structured_formatting']['secondary_text'];

  }
}
