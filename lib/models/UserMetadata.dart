/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the UserMetadata type in your schema. */
class UserMetadata extends amplify_core.Model {
  static const classType = const _UserMetadataModelType();
  final String id;
  final String? _participant;
  final String? _start_study_date;
  final String? _next_study_date;
  final String? _recent_submit_date;
  final String? _day1;
  final String? _day2;
  final String? _day3;
  final String? _day4;
  final String? _day5;
  final String? _day6;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserMetadataModelIdentifier get modelIdentifier {
      return UserMetadataModelIdentifier(
        id: id
      );
  }
  
  String? get participant {
    return _participant;
  }
  
  String? get start_study_date {
    return _start_study_date;
  }
  
  String? get next_study_date {
    return _next_study_date;
  }
  
  String? get recent_submit_date {
    return _recent_submit_date;
  }
  
  String? get day1 {
    return _day1;
  }
  
  String? get day2 {
    return _day2;
  }
  
  String? get day3 {
    return _day3;
  }
  
  String? get day4 {
    return _day4;
  }
  
  String? get day5 {
    return _day5;
  }
  
  String? get day6 {
    return _day6;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserMetadata._internal({required this.id, participant, start_study_date, next_study_date, recent_submit_date, day1, day2, day3, day4, day5, day6, createdAt, updatedAt}): _participant = participant, _start_study_date = start_study_date, _next_study_date = next_study_date, _recent_submit_date = recent_submit_date, _day1 = day1, _day2 = day2, _day3 = day3, _day4 = day4, _day5 = day5, _day6 = day6, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserMetadata({String? id, String? participant, String? start_study_date, String? next_study_date, String? recent_submit_date, String? day1, String? day2, String? day3, String? day4, String? day5, String? day6}) {
    return UserMetadata._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      participant: participant,
      start_study_date: start_study_date,
      next_study_date: next_study_date,
      recent_submit_date: recent_submit_date,
      day1: day1,
      day2: day2,
      day3: day3,
      day4: day4,
      day5: day5,
      day6: day6);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserMetadata &&
      id == other.id &&
      _participant == other._participant &&
      _start_study_date == other._start_study_date &&
      _next_study_date == other._next_study_date &&
      _recent_submit_date == other._recent_submit_date &&
      _day1 == other._day1 &&
      _day2 == other._day2 &&
      _day3 == other._day3 &&
      _day4 == other._day4 &&
      _day5 == other._day5 &&
      _day6 == other._day6;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserMetadata {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("participant=" + "$_participant" + ", ");
    buffer.write("start_study_date=" + "$_start_study_date" + ", ");
    buffer.write("next_study_date=" + "$_next_study_date" + ", ");
    buffer.write("recent_submit_date=" + "$_recent_submit_date" + ", ");
    buffer.write("day1=" + "$_day1" + ", ");
    buffer.write("day2=" + "$_day2" + ", ");
    buffer.write("day3=" + "$_day3" + ", ");
    buffer.write("day4=" + "$_day4" + ", ");
    buffer.write("day5=" + "$_day5" + ", ");
    buffer.write("day6=" + "$_day6" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserMetadata copyWith({String? participant, String? start_study_date, String? next_study_date, String? recent_submit_date, String? day1, String? day2, String? day3, String? day4, String? day5, String? day6}) {
    return UserMetadata._internal(
      id: id,
      participant: participant ?? this.participant,
      start_study_date: start_study_date ?? this.start_study_date,
      next_study_date: next_study_date ?? this.next_study_date,
      recent_submit_date: recent_submit_date ?? this.recent_submit_date,
      day1: day1 ?? this.day1,
      day2: day2 ?? this.day2,
      day3: day3 ?? this.day3,
      day4: day4 ?? this.day4,
      day5: day5 ?? this.day5,
      day6: day6 ?? this.day6);
  }
  
  UserMetadata copyWithModelFieldValues({
    ModelFieldValue<String?>? participant,
    ModelFieldValue<String?>? start_study_date,
    ModelFieldValue<String?>? next_study_date,
    ModelFieldValue<String?>? recent_submit_date,
    ModelFieldValue<String?>? day1,
    ModelFieldValue<String?>? day2,
    ModelFieldValue<String?>? day3,
    ModelFieldValue<String?>? day4,
    ModelFieldValue<String?>? day5,
    ModelFieldValue<String?>? day6
  }) {
    return UserMetadata._internal(
      id: id,
      participant: participant == null ? this.participant : participant.value,
      start_study_date: start_study_date == null ? this.start_study_date : start_study_date.value,
      next_study_date: next_study_date == null ? this.next_study_date : next_study_date.value,
      recent_submit_date: recent_submit_date == null ? this.recent_submit_date : recent_submit_date.value,
      day1: day1 == null ? this.day1 : day1.value,
      day2: day2 == null ? this.day2 : day2.value,
      day3: day3 == null ? this.day3 : day3.value,
      day4: day4 == null ? this.day4 : day4.value,
      day5: day5 == null ? this.day5 : day5.value,
      day6: day6 == null ? this.day6 : day6.value
    );
  }
  
  UserMetadata.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _participant = json['participant'],
      _start_study_date = json['start_study_date'],
      _next_study_date = json['next_study_date'],
      _recent_submit_date = json['recent_submit_date'],
      _day1 = json['day1'],
      _day2 = json['day2'],
      _day3 = json['day3'],
      _day4 = json['day4'],
      _day5 = json['day5'],
      _day6 = json['day6'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'participant': _participant, 'start_study_date': _start_study_date, 'next_study_date': _next_study_date, 'recent_submit_date': _recent_submit_date, 'day1': _day1, 'day2': _day2, 'day3': _day3, 'day4': _day4, 'day5': _day5, 'day6': _day6, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'participant': _participant,
    'start_study_date': _start_study_date,
    'next_study_date': _next_study_date,
    'recent_submit_date': _recent_submit_date,
    'day1': _day1,
    'day2': _day2,
    'day3': _day3,
    'day4': _day4,
    'day5': _day5,
    'day6': _day6,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserMetadataModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserMetadataModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final PARTICIPANT = amplify_core.QueryField(fieldName: "participant");
  static final START_STUDY_DATE = amplify_core.QueryField(fieldName: "start_study_date");
  static final NEXT_STUDY_DATE = amplify_core.QueryField(fieldName: "next_study_date");
  static final RECENT_SUBMIT_DATE = amplify_core.QueryField(fieldName: "recent_submit_date");
  static final DAY1 = amplify_core.QueryField(fieldName: "day1");
  static final DAY2 = amplify_core.QueryField(fieldName: "day2");
  static final DAY3 = amplify_core.QueryField(fieldName: "day3");
  static final DAY4 = amplify_core.QueryField(fieldName: "day4");
  static final DAY5 = amplify_core.QueryField(fieldName: "day5");
  static final DAY6 = amplify_core.QueryField(fieldName: "day6");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserMetadata";
    modelSchemaDefinition.pluralName = "UserMetadata";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.PARTICIPANT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.START_STUDY_DATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.NEXT_STUDY_DATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.RECENT_SUBMIT_DATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserMetadata.DAY6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _UserMetadataModelType extends amplify_core.ModelType<UserMetadata> {
  const _UserMetadataModelType();
  
  @override
  UserMetadata fromJson(Map<String, dynamic> jsonData) {
    return UserMetadata.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserMetadata';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserMetadata] in your schema.
 */
class UserMetadataModelIdentifier implements amplify_core.ModelIdentifier<UserMetadata> {
  final String id;

  /** Create an instance of UserMetadataModelIdentifier using [id] the primary key. */
  const UserMetadataModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'UserMetadataModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserMetadataModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}