class Credentials {
  String? authorization;
  String? xapikey;
  // ignore: non_constant_identifier_names
  String? dynamo_url;
  // ignore: non_constant_identifier_names
  String? presigned_url;

  Credentials(
      // ignore: non_constant_identifier_names
      {this.authorization,
      this.xapikey,
      this.dynamo_url,
      this.presigned_url});

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(
        authorization: json['authorization'],
        xapikey: json['x-api-key'],
        dynamo_url: json['dynamo_url'],
        presigned_url: json['presigned_url']);
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization': authorization,
      'x-api-key': xapikey,
      'dynamo_url': dynamo_url,
      'presigned_url': presigned_url
    };
  }
}
