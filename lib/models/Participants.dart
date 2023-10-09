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

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the Participants type in your schema. */
class Participants extends amplify_core.Model {
  static const classType = const _ParticipantsModelType();
  final String id;
  final String? _STUDYCODE;
  final int? _PHYSICALLY_1;
  final int? _PHYSICALLY_2;
  final int? _PHYSICALLY_3;
  final int? _PHYSICALLY_4;
  final int? _PHYSICALLY_5;
  final int? _PHYSICALLY_6;
  final int? _EMOTIONALLY_1;
  final int? _EMOTIONALLY_2;
  final int? _EMOTIONALLY_3;
  final int? _EMOTIONALLY_4;
  final int? _EMOTIONALLY_5;
  final int? _EMOTIONALLY_6;
  final int? _INTENSITY_1;
  final int? _INTENSITY_2;
  final int? _INTENSITY_3;
  final int? _INTENSITY_4;
  final int? _INTENSITY_5;
  final int? _INTENSITY_6;
  final int? _LONELY_1;
  final int? _LONELY_2;
  final int? _LONELY_3;
  final int? _LONELY_4;
  final int? _LONELY_5;
  final int? _LONELY_6;
  final int? _LEFT_OUT_1;
  final int? _LEFT_OUT_2;
  final int? _LEFT_OUT_3;
  final int? _LEFT_OUT_4;
  final int? _LEFT_OUT_5;
  final int? _LEFT_OUT_6;
  final int? _SOCIAL_INTERACTION_1;
  final int? _SOCIAL_INTERACTION_2;
  final int? _SOCIAL_INTERACTION_3;
  final int? _SOCIAL_INTERACTION_4;
  final int? _SOCIAL_INTERACTION_5;
  final int? _SOCIAL_INTERACTION_6;
  final int? _UNDERSTOOD_1;
  final int? _UNDERSTOOD_2;
  final int? _UNDERSTOOD_3;
  final int? _UNDERSTOOD_4;
  final int? _UNDERSTOOD_5;
  final int? _UNDERSTOOD_6;
  final int? _STRESSED_1;
  final int? _STRESSED_2;
  final int? _STRESSED_3;
  final int? _STRESSED_4;
  final int? _STRESSED_5;
  final int? _STRESSED_6;
  final String? _WHERE_YOU_ARE_1;
  final String? _WHERE_YOU_ARE_2;
  final String? _WHERE_YOU_ARE_3;
  final String? _WHERE_YOU_ARE_4;
  final String? _WHERE_YOU_ARE_5;
  final String? _WHERE_YOU_ARE_6;
  final String? _PEOPLE_AROUND_YOU_1;
  final String? _PEOPLE_AROUND_YOU_2;
  final String? _PEOPLE_AROUND_YOU_3;
  final String? _PEOPLE_AROUND_YOU_4;
  final String? _PEOPLE_AROUND_YOU_5;
  final String? _PEOPLE_AROUND_YOU_6;
  final int? _DRINKS_1;
  final int? _DRINKS_2;
  final int? _DRINKS_3;
  final int? _DRINKS_4;
  final int? _DRINKS_5;
  final int? _DRINKS_6;
  final String? _STARTTIME;
  final String? _ENDTIME;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ParticipantsModelIdentifier get modelIdentifier {
      return ParticipantsModelIdentifier(
        id: id
      );
  }
  
  String get STUDYCODE {
    try {
      return _STUDYCODE!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int? get PHYSICALLY_1 {
    return _PHYSICALLY_1;
  }
  
  int? get PHYSICALLY_2 {
    return _PHYSICALLY_2;
  }
  
  int? get PHYSICALLY_3 {
    return _PHYSICALLY_3;
  }
  
  int? get PHYSICALLY_4 {
    return _PHYSICALLY_4;
  }
  
  int? get PHYSICALLY_5 {
    return _PHYSICALLY_5;
  }
  
  int? get PHYSICALLY_6 {
    return _PHYSICALLY_6;
  }
  
  int? get EMOTIONALLY_1 {
    return _EMOTIONALLY_1;
  }
  
  int? get EMOTIONALLY_2 {
    return _EMOTIONALLY_2;
  }
  
  int? get EMOTIONALLY_3 {
    return _EMOTIONALLY_3;
  }
  
  int? get EMOTIONALLY_4 {
    return _EMOTIONALLY_4;
  }
  
  int? get EMOTIONALLY_5 {
    return _EMOTIONALLY_5;
  }
  
  int? get EMOTIONALLY_6 {
    return _EMOTIONALLY_6;
  }
  
  int? get INTENSITY_1 {
    return _INTENSITY_1;
  }
  
  int? get INTENSITY_2 {
    return _INTENSITY_2;
  }
  
  int? get INTENSITY_3 {
    return _INTENSITY_3;
  }
  
  int? get INTENSITY_4 {
    return _INTENSITY_4;
  }
  
  int? get INTENSITY_5 {
    return _INTENSITY_5;
  }
  
  int? get INTENSITY_6 {
    return _INTENSITY_6;
  }
  
  int? get LONELY_1 {
    return _LONELY_1;
  }
  
  int? get LONELY_2 {
    return _LONELY_2;
  }
  
  int? get LONELY_3 {
    return _LONELY_3;
  }
  
  int? get LONELY_4 {
    return _LONELY_4;
  }
  
  int? get LONELY_5 {
    return _LONELY_5;
  }
  
  int? get LONELY_6 {
    return _LONELY_6;
  }
  
  int? get LEFT_OUT_1 {
    return _LEFT_OUT_1;
  }
  
  int? get LEFT_OUT_2 {
    return _LEFT_OUT_2;
  }
  
  int? get LEFT_OUT_3 {
    return _LEFT_OUT_3;
  }
  
  int? get LEFT_OUT_4 {
    return _LEFT_OUT_4;
  }
  
  int? get LEFT_OUT_5 {
    return _LEFT_OUT_5;
  }
  
  int? get LEFT_OUT_6 {
    return _LEFT_OUT_6;
  }
  
  int? get SOCIAL_INTERACTION_1 {
    return _SOCIAL_INTERACTION_1;
  }
  
  int? get SOCIAL_INTERACTION_2 {
    return _SOCIAL_INTERACTION_2;
  }
  
  int? get SOCIAL_INTERACTION_3 {
    return _SOCIAL_INTERACTION_3;
  }
  
  int? get SOCIAL_INTERACTION_4 {
    return _SOCIAL_INTERACTION_4;
  }
  
  int? get SOCIAL_INTERACTION_5 {
    return _SOCIAL_INTERACTION_5;
  }
  
  int? get SOCIAL_INTERACTION_6 {
    return _SOCIAL_INTERACTION_6;
  }
  
  int? get UNDERSTOOD_1 {
    return _UNDERSTOOD_1;
  }
  
  int? get UNDERSTOOD_2 {
    return _UNDERSTOOD_2;
  }
  
  int? get UNDERSTOOD_3 {
    return _UNDERSTOOD_3;
  }
  
  int? get UNDERSTOOD_4 {
    return _UNDERSTOOD_4;
  }
  
  int? get UNDERSTOOD_5 {
    return _UNDERSTOOD_5;
  }
  
  int? get UNDERSTOOD_6 {
    return _UNDERSTOOD_6;
  }
  
  int? get STRESSED_1 {
    return _STRESSED_1;
  }
  
  int? get STRESSED_2 {
    return _STRESSED_2;
  }
  
  int? get STRESSED_3 {
    return _STRESSED_3;
  }
  
  int? get STRESSED_4 {
    return _STRESSED_4;
  }
  
  int? get STRESSED_5 {
    return _STRESSED_5;
  }
  
  int? get STRESSED_6 {
    return _STRESSED_6;
  }
  
  String? get WHERE_YOU_ARE_1 {
    return _WHERE_YOU_ARE_1;
  }
  
  String? get WHERE_YOU_ARE_2 {
    return _WHERE_YOU_ARE_2;
  }
  
  String? get WHERE_YOU_ARE_3 {
    return _WHERE_YOU_ARE_3;
  }
  
  String? get WHERE_YOU_ARE_4 {
    return _WHERE_YOU_ARE_4;
  }
  
  String? get WHERE_YOU_ARE_5 {
    return _WHERE_YOU_ARE_5;
  }
  
  String? get WHERE_YOU_ARE_6 {
    return _WHERE_YOU_ARE_6;
  }
  
  String? get PEOPLE_AROUND_YOU_1 {
    return _PEOPLE_AROUND_YOU_1;
  }
  
  String? get PEOPLE_AROUND_YOU_2 {
    return _PEOPLE_AROUND_YOU_2;
  }
  
  String? get PEOPLE_AROUND_YOU_3 {
    return _PEOPLE_AROUND_YOU_3;
  }
  
  String? get PEOPLE_AROUND_YOU_4 {
    return _PEOPLE_AROUND_YOU_4;
  }
  
  String? get PEOPLE_AROUND_YOU_5 {
    return _PEOPLE_AROUND_YOU_5;
  }
  
  String? get PEOPLE_AROUND_YOU_6 {
    return _PEOPLE_AROUND_YOU_6;
  }
  
  int? get DRINKS_1 {
    return _DRINKS_1;
  }
  
  int? get DRINKS_2 {
    return _DRINKS_2;
  }
  
  int? get DRINKS_3 {
    return _DRINKS_3;
  }
  
  int? get DRINKS_4 {
    return _DRINKS_4;
  }
  
  int? get DRINKS_5 {
    return _DRINKS_5;
  }
  
  int? get DRINKS_6 {
    return _DRINKS_6;
  }
  
  String? get STARTTIME {
    return _STARTTIME;
  }
  
  String? get ENDTIME {
    return _ENDTIME;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Participants._internal({required this.id, required STUDYCODE, PHYSICALLY_1, PHYSICALLY_2, PHYSICALLY_3, PHYSICALLY_4, PHYSICALLY_5, PHYSICALLY_6, EMOTIONALLY_1, EMOTIONALLY_2, EMOTIONALLY_3, EMOTIONALLY_4, EMOTIONALLY_5, EMOTIONALLY_6, INTENSITY_1, INTENSITY_2, INTENSITY_3, INTENSITY_4, INTENSITY_5, INTENSITY_6, LONELY_1, LONELY_2, LONELY_3, LONELY_4, LONELY_5, LONELY_6, LEFT_OUT_1, LEFT_OUT_2, LEFT_OUT_3, LEFT_OUT_4, LEFT_OUT_5, LEFT_OUT_6, SOCIAL_INTERACTION_1, SOCIAL_INTERACTION_2, SOCIAL_INTERACTION_3, SOCIAL_INTERACTION_4, SOCIAL_INTERACTION_5, SOCIAL_INTERACTION_6, UNDERSTOOD_1, UNDERSTOOD_2, UNDERSTOOD_3, UNDERSTOOD_4, UNDERSTOOD_5, UNDERSTOOD_6, STRESSED_1, STRESSED_2, STRESSED_3, STRESSED_4, STRESSED_5, STRESSED_6, WHERE_YOU_ARE_1, WHERE_YOU_ARE_2, WHERE_YOU_ARE_3, WHERE_YOU_ARE_4, WHERE_YOU_ARE_5, WHERE_YOU_ARE_6, PEOPLE_AROUND_YOU_1, PEOPLE_AROUND_YOU_2, PEOPLE_AROUND_YOU_3, PEOPLE_AROUND_YOU_4, PEOPLE_AROUND_YOU_5, PEOPLE_AROUND_YOU_6, DRINKS_1, DRINKS_2, DRINKS_3, DRINKS_4, DRINKS_5, DRINKS_6, STARTTIME, ENDTIME, createdAt, updatedAt}): _STUDYCODE = STUDYCODE, _PHYSICALLY_1 = PHYSICALLY_1, _PHYSICALLY_2 = PHYSICALLY_2, _PHYSICALLY_3 = PHYSICALLY_3, _PHYSICALLY_4 = PHYSICALLY_4, _PHYSICALLY_5 = PHYSICALLY_5, _PHYSICALLY_6 = PHYSICALLY_6, _EMOTIONALLY_1 = EMOTIONALLY_1, _EMOTIONALLY_2 = EMOTIONALLY_2, _EMOTIONALLY_3 = EMOTIONALLY_3, _EMOTIONALLY_4 = EMOTIONALLY_4, _EMOTIONALLY_5 = EMOTIONALLY_5, _EMOTIONALLY_6 = EMOTIONALLY_6, _INTENSITY_1 = INTENSITY_1, _INTENSITY_2 = INTENSITY_2, _INTENSITY_3 = INTENSITY_3, _INTENSITY_4 = INTENSITY_4, _INTENSITY_5 = INTENSITY_5, _INTENSITY_6 = INTENSITY_6, _LONELY_1 = LONELY_1, _LONELY_2 = LONELY_2, _LONELY_3 = LONELY_3, _LONELY_4 = LONELY_4, _LONELY_5 = LONELY_5, _LONELY_6 = LONELY_6, _LEFT_OUT_1 = LEFT_OUT_1, _LEFT_OUT_2 = LEFT_OUT_2, _LEFT_OUT_3 = LEFT_OUT_3, _LEFT_OUT_4 = LEFT_OUT_4, _LEFT_OUT_5 = LEFT_OUT_5, _LEFT_OUT_6 = LEFT_OUT_6, _SOCIAL_INTERACTION_1 = SOCIAL_INTERACTION_1, _SOCIAL_INTERACTION_2 = SOCIAL_INTERACTION_2, _SOCIAL_INTERACTION_3 = SOCIAL_INTERACTION_3, _SOCIAL_INTERACTION_4 = SOCIAL_INTERACTION_4, _SOCIAL_INTERACTION_5 = SOCIAL_INTERACTION_5, _SOCIAL_INTERACTION_6 = SOCIAL_INTERACTION_6, _UNDERSTOOD_1 = UNDERSTOOD_1, _UNDERSTOOD_2 = UNDERSTOOD_2, _UNDERSTOOD_3 = UNDERSTOOD_3, _UNDERSTOOD_4 = UNDERSTOOD_4, _UNDERSTOOD_5 = UNDERSTOOD_5, _UNDERSTOOD_6 = UNDERSTOOD_6, _STRESSED_1 = STRESSED_1, _STRESSED_2 = STRESSED_2, _STRESSED_3 = STRESSED_3, _STRESSED_4 = STRESSED_4, _STRESSED_5 = STRESSED_5, _STRESSED_6 = STRESSED_6, _WHERE_YOU_ARE_1 = WHERE_YOU_ARE_1, _WHERE_YOU_ARE_2 = WHERE_YOU_ARE_2, _WHERE_YOU_ARE_3 = WHERE_YOU_ARE_3, _WHERE_YOU_ARE_4 = WHERE_YOU_ARE_4, _WHERE_YOU_ARE_5 = WHERE_YOU_ARE_5, _WHERE_YOU_ARE_6 = WHERE_YOU_ARE_6, _PEOPLE_AROUND_YOU_1 = PEOPLE_AROUND_YOU_1, _PEOPLE_AROUND_YOU_2 = PEOPLE_AROUND_YOU_2, _PEOPLE_AROUND_YOU_3 = PEOPLE_AROUND_YOU_3, _PEOPLE_AROUND_YOU_4 = PEOPLE_AROUND_YOU_4, _PEOPLE_AROUND_YOU_5 = PEOPLE_AROUND_YOU_5, _PEOPLE_AROUND_YOU_6 = PEOPLE_AROUND_YOU_6, _DRINKS_1 = DRINKS_1, _DRINKS_2 = DRINKS_2, _DRINKS_3 = DRINKS_3, _DRINKS_4 = DRINKS_4, _DRINKS_5 = DRINKS_5, _DRINKS_6 = DRINKS_6, _STARTTIME = STARTTIME, _ENDTIME = ENDTIME, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Participants({String? id, required String STUDYCODE, int? PHYSICALLY_1, int? PHYSICALLY_2, int? PHYSICALLY_3, int? PHYSICALLY_4, int? PHYSICALLY_5, int? PHYSICALLY_6, int? EMOTIONALLY_1, int? EMOTIONALLY_2, int? EMOTIONALLY_3, int? EMOTIONALLY_4, int? EMOTIONALLY_5, int? EMOTIONALLY_6, int? INTENSITY_1, int? INTENSITY_2, int? INTENSITY_3, int? INTENSITY_4, int? INTENSITY_5, int? INTENSITY_6, int? LONELY_1, int? LONELY_2, int? LONELY_3, int? LONELY_4, int? LONELY_5, int? LONELY_6, int? LEFT_OUT_1, int? LEFT_OUT_2, int? LEFT_OUT_3, int? LEFT_OUT_4, int? LEFT_OUT_5, int? LEFT_OUT_6, int? SOCIAL_INTERACTION_1, int? SOCIAL_INTERACTION_2, int? SOCIAL_INTERACTION_3, int? SOCIAL_INTERACTION_4, int? SOCIAL_INTERACTION_5, int? SOCIAL_INTERACTION_6, int? UNDERSTOOD_1, int? UNDERSTOOD_2, int? UNDERSTOOD_3, int? UNDERSTOOD_4, int? UNDERSTOOD_5, int? UNDERSTOOD_6, int? STRESSED_1, int? STRESSED_2, int? STRESSED_3, int? STRESSED_4, int? STRESSED_5, int? STRESSED_6, String? WHERE_YOU_ARE_1, String? WHERE_YOU_ARE_2, String? WHERE_YOU_ARE_3, String? WHERE_YOU_ARE_4, String? WHERE_YOU_ARE_5, String? WHERE_YOU_ARE_6, String? PEOPLE_AROUND_YOU_1, String? PEOPLE_AROUND_YOU_2, String? PEOPLE_AROUND_YOU_3, String? PEOPLE_AROUND_YOU_4, String? PEOPLE_AROUND_YOU_5, String? PEOPLE_AROUND_YOU_6, int? DRINKS_1, int? DRINKS_2, int? DRINKS_3, int? DRINKS_4, int? DRINKS_5, int? DRINKS_6, String? STARTTIME, String? ENDTIME}) {
    return Participants._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      STUDYCODE: STUDYCODE,
      PHYSICALLY_1: PHYSICALLY_1,
      PHYSICALLY_2: PHYSICALLY_2,
      PHYSICALLY_3: PHYSICALLY_3,
      PHYSICALLY_4: PHYSICALLY_4,
      PHYSICALLY_5: PHYSICALLY_5,
      PHYSICALLY_6: PHYSICALLY_6,
      EMOTIONALLY_1: EMOTIONALLY_1,
      EMOTIONALLY_2: EMOTIONALLY_2,
      EMOTIONALLY_3: EMOTIONALLY_3,
      EMOTIONALLY_4: EMOTIONALLY_4,
      EMOTIONALLY_5: EMOTIONALLY_5,
      EMOTIONALLY_6: EMOTIONALLY_6,
      INTENSITY_1: INTENSITY_1,
      INTENSITY_2: INTENSITY_2,
      INTENSITY_3: INTENSITY_3,
      INTENSITY_4: INTENSITY_4,
      INTENSITY_5: INTENSITY_5,
      INTENSITY_6: INTENSITY_6,
      LONELY_1: LONELY_1,
      LONELY_2: LONELY_2,
      LONELY_3: LONELY_3,
      LONELY_4: LONELY_4,
      LONELY_5: LONELY_5,
      LONELY_6: LONELY_6,
      LEFT_OUT_1: LEFT_OUT_1,
      LEFT_OUT_2: LEFT_OUT_2,
      LEFT_OUT_3: LEFT_OUT_3,
      LEFT_OUT_4: LEFT_OUT_4,
      LEFT_OUT_5: LEFT_OUT_5,
      LEFT_OUT_6: LEFT_OUT_6,
      SOCIAL_INTERACTION_1: SOCIAL_INTERACTION_1,
      SOCIAL_INTERACTION_2: SOCIAL_INTERACTION_2,
      SOCIAL_INTERACTION_3: SOCIAL_INTERACTION_3,
      SOCIAL_INTERACTION_4: SOCIAL_INTERACTION_4,
      SOCIAL_INTERACTION_5: SOCIAL_INTERACTION_5,
      SOCIAL_INTERACTION_6: SOCIAL_INTERACTION_6,
      UNDERSTOOD_1: UNDERSTOOD_1,
      UNDERSTOOD_2: UNDERSTOOD_2,
      UNDERSTOOD_3: UNDERSTOOD_3,
      UNDERSTOOD_4: UNDERSTOOD_4,
      UNDERSTOOD_5: UNDERSTOOD_5,
      UNDERSTOOD_6: UNDERSTOOD_6,
      STRESSED_1: STRESSED_1,
      STRESSED_2: STRESSED_2,
      STRESSED_3: STRESSED_3,
      STRESSED_4: STRESSED_4,
      STRESSED_5: STRESSED_5,
      STRESSED_6: STRESSED_6,
      WHERE_YOU_ARE_1: WHERE_YOU_ARE_1,
      WHERE_YOU_ARE_2: WHERE_YOU_ARE_2,
      WHERE_YOU_ARE_3: WHERE_YOU_ARE_3,
      WHERE_YOU_ARE_4: WHERE_YOU_ARE_4,
      WHERE_YOU_ARE_5: WHERE_YOU_ARE_5,
      WHERE_YOU_ARE_6: WHERE_YOU_ARE_6,
      PEOPLE_AROUND_YOU_1: PEOPLE_AROUND_YOU_1,
      PEOPLE_AROUND_YOU_2: PEOPLE_AROUND_YOU_2,
      PEOPLE_AROUND_YOU_3: PEOPLE_AROUND_YOU_3,
      PEOPLE_AROUND_YOU_4: PEOPLE_AROUND_YOU_4,
      PEOPLE_AROUND_YOU_5: PEOPLE_AROUND_YOU_5,
      PEOPLE_AROUND_YOU_6: PEOPLE_AROUND_YOU_6,
      DRINKS_1: DRINKS_1,
      DRINKS_2: DRINKS_2,
      DRINKS_3: DRINKS_3,
      DRINKS_4: DRINKS_4,
      DRINKS_5: DRINKS_5,
      DRINKS_6: DRINKS_6,
      STARTTIME: STARTTIME,
      ENDTIME: ENDTIME);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Participants &&
      id == other.id &&
      _STUDYCODE == other._STUDYCODE &&
      _PHYSICALLY_1 == other._PHYSICALLY_1 &&
      _PHYSICALLY_2 == other._PHYSICALLY_2 &&
      _PHYSICALLY_3 == other._PHYSICALLY_3 &&
      _PHYSICALLY_4 == other._PHYSICALLY_4 &&
      _PHYSICALLY_5 == other._PHYSICALLY_5 &&
      _PHYSICALLY_6 == other._PHYSICALLY_6 &&
      _EMOTIONALLY_1 == other._EMOTIONALLY_1 &&
      _EMOTIONALLY_2 == other._EMOTIONALLY_2 &&
      _EMOTIONALLY_3 == other._EMOTIONALLY_3 &&
      _EMOTIONALLY_4 == other._EMOTIONALLY_4 &&
      _EMOTIONALLY_5 == other._EMOTIONALLY_5 &&
      _EMOTIONALLY_6 == other._EMOTIONALLY_6 &&
      _INTENSITY_1 == other._INTENSITY_1 &&
      _INTENSITY_2 == other._INTENSITY_2 &&
      _INTENSITY_3 == other._INTENSITY_3 &&
      _INTENSITY_4 == other._INTENSITY_4 &&
      _INTENSITY_5 == other._INTENSITY_5 &&
      _INTENSITY_6 == other._INTENSITY_6 &&
      _LONELY_1 == other._LONELY_1 &&
      _LONELY_2 == other._LONELY_2 &&
      _LONELY_3 == other._LONELY_3 &&
      _LONELY_4 == other._LONELY_4 &&
      _LONELY_5 == other._LONELY_5 &&
      _LONELY_6 == other._LONELY_6 &&
      _LEFT_OUT_1 == other._LEFT_OUT_1 &&
      _LEFT_OUT_2 == other._LEFT_OUT_2 &&
      _LEFT_OUT_3 == other._LEFT_OUT_3 &&
      _LEFT_OUT_4 == other._LEFT_OUT_4 &&
      _LEFT_OUT_5 == other._LEFT_OUT_5 &&
      _LEFT_OUT_6 == other._LEFT_OUT_6 &&
      _SOCIAL_INTERACTION_1 == other._SOCIAL_INTERACTION_1 &&
      _SOCIAL_INTERACTION_2 == other._SOCIAL_INTERACTION_2 &&
      _SOCIAL_INTERACTION_3 == other._SOCIAL_INTERACTION_3 &&
      _SOCIAL_INTERACTION_4 == other._SOCIAL_INTERACTION_4 &&
      _SOCIAL_INTERACTION_5 == other._SOCIAL_INTERACTION_5 &&
      _SOCIAL_INTERACTION_6 == other._SOCIAL_INTERACTION_6 &&
      _UNDERSTOOD_1 == other._UNDERSTOOD_1 &&
      _UNDERSTOOD_2 == other._UNDERSTOOD_2 &&
      _UNDERSTOOD_3 == other._UNDERSTOOD_3 &&
      _UNDERSTOOD_4 == other._UNDERSTOOD_4 &&
      _UNDERSTOOD_5 == other._UNDERSTOOD_5 &&
      _UNDERSTOOD_6 == other._UNDERSTOOD_6 &&
      _STRESSED_1 == other._STRESSED_1 &&
      _STRESSED_2 == other._STRESSED_2 &&
      _STRESSED_3 == other._STRESSED_3 &&
      _STRESSED_4 == other._STRESSED_4 &&
      _STRESSED_5 == other._STRESSED_5 &&
      _STRESSED_6 == other._STRESSED_6 &&
      _WHERE_YOU_ARE_1 == other._WHERE_YOU_ARE_1 &&
      _WHERE_YOU_ARE_2 == other._WHERE_YOU_ARE_2 &&
      _WHERE_YOU_ARE_3 == other._WHERE_YOU_ARE_3 &&
      _WHERE_YOU_ARE_4 == other._WHERE_YOU_ARE_4 &&
      _WHERE_YOU_ARE_5 == other._WHERE_YOU_ARE_5 &&
      _WHERE_YOU_ARE_6 == other._WHERE_YOU_ARE_6 &&
      _PEOPLE_AROUND_YOU_1 == other._PEOPLE_AROUND_YOU_1 &&
      _PEOPLE_AROUND_YOU_2 == other._PEOPLE_AROUND_YOU_2 &&
      _PEOPLE_AROUND_YOU_3 == other._PEOPLE_AROUND_YOU_3 &&
      _PEOPLE_AROUND_YOU_4 == other._PEOPLE_AROUND_YOU_4 &&
      _PEOPLE_AROUND_YOU_5 == other._PEOPLE_AROUND_YOU_5 &&
      _PEOPLE_AROUND_YOU_6 == other._PEOPLE_AROUND_YOU_6 &&
      _DRINKS_1 == other._DRINKS_1 &&
      _DRINKS_2 == other._DRINKS_2 &&
      _DRINKS_3 == other._DRINKS_3 &&
      _DRINKS_4 == other._DRINKS_4 &&
      _DRINKS_5 == other._DRINKS_5 &&
      _DRINKS_6 == other._DRINKS_6 &&
      _STARTTIME == other._STARTTIME &&
      _ENDTIME == other._ENDTIME;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Participants {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("STUDYCODE=" + "$_STUDYCODE" + ", ");
    buffer.write("PHYSICALLY_1=" + (_PHYSICALLY_1 != null ? _PHYSICALLY_1!.toString() : "null") + ", ");
    buffer.write("PHYSICALLY_2=" + (_PHYSICALLY_2 != null ? _PHYSICALLY_2!.toString() : "null") + ", ");
    buffer.write("PHYSICALLY_3=" + (_PHYSICALLY_3 != null ? _PHYSICALLY_3!.toString() : "null") + ", ");
    buffer.write("PHYSICALLY_4=" + (_PHYSICALLY_4 != null ? _PHYSICALLY_4!.toString() : "null") + ", ");
    buffer.write("PHYSICALLY_5=" + (_PHYSICALLY_5 != null ? _PHYSICALLY_5!.toString() : "null") + ", ");
    buffer.write("PHYSICALLY_6=" + (_PHYSICALLY_6 != null ? _PHYSICALLY_6!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_1=" + (_EMOTIONALLY_1 != null ? _EMOTIONALLY_1!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_2=" + (_EMOTIONALLY_2 != null ? _EMOTIONALLY_2!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_3=" + (_EMOTIONALLY_3 != null ? _EMOTIONALLY_3!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_4=" + (_EMOTIONALLY_4 != null ? _EMOTIONALLY_4!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_5=" + (_EMOTIONALLY_5 != null ? _EMOTIONALLY_5!.toString() : "null") + ", ");
    buffer.write("EMOTIONALLY_6=" + (_EMOTIONALLY_6 != null ? _EMOTIONALLY_6!.toString() : "null") + ", ");
    buffer.write("INTENSITY_1=" + (_INTENSITY_1 != null ? _INTENSITY_1!.toString() : "null") + ", ");
    buffer.write("INTENSITY_2=" + (_INTENSITY_2 != null ? _INTENSITY_2!.toString() : "null") + ", ");
    buffer.write("INTENSITY_3=" + (_INTENSITY_3 != null ? _INTENSITY_3!.toString() : "null") + ", ");
    buffer.write("INTENSITY_4=" + (_INTENSITY_4 != null ? _INTENSITY_4!.toString() : "null") + ", ");
    buffer.write("INTENSITY_5=" + (_INTENSITY_5 != null ? _INTENSITY_5!.toString() : "null") + ", ");
    buffer.write("INTENSITY_6=" + (_INTENSITY_6 != null ? _INTENSITY_6!.toString() : "null") + ", ");
    buffer.write("LONELY_1=" + (_LONELY_1 != null ? _LONELY_1!.toString() : "null") + ", ");
    buffer.write("LONELY_2=" + (_LONELY_2 != null ? _LONELY_2!.toString() : "null") + ", ");
    buffer.write("LONELY_3=" + (_LONELY_3 != null ? _LONELY_3!.toString() : "null") + ", ");
    buffer.write("LONELY_4=" + (_LONELY_4 != null ? _LONELY_4!.toString() : "null") + ", ");
    buffer.write("LONELY_5=" + (_LONELY_5 != null ? _LONELY_5!.toString() : "null") + ", ");
    buffer.write("LONELY_6=" + (_LONELY_6 != null ? _LONELY_6!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_1=" + (_LEFT_OUT_1 != null ? _LEFT_OUT_1!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_2=" + (_LEFT_OUT_2 != null ? _LEFT_OUT_2!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_3=" + (_LEFT_OUT_3 != null ? _LEFT_OUT_3!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_4=" + (_LEFT_OUT_4 != null ? _LEFT_OUT_4!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_5=" + (_LEFT_OUT_5 != null ? _LEFT_OUT_5!.toString() : "null") + ", ");
    buffer.write("LEFT_OUT_6=" + (_LEFT_OUT_6 != null ? _LEFT_OUT_6!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_1=" + (_SOCIAL_INTERACTION_1 != null ? _SOCIAL_INTERACTION_1!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_2=" + (_SOCIAL_INTERACTION_2 != null ? _SOCIAL_INTERACTION_2!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_3=" + (_SOCIAL_INTERACTION_3 != null ? _SOCIAL_INTERACTION_3!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_4=" + (_SOCIAL_INTERACTION_4 != null ? _SOCIAL_INTERACTION_4!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_5=" + (_SOCIAL_INTERACTION_5 != null ? _SOCIAL_INTERACTION_5!.toString() : "null") + ", ");
    buffer.write("SOCIAL_INTERACTION_6=" + (_SOCIAL_INTERACTION_6 != null ? _SOCIAL_INTERACTION_6!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_1=" + (_UNDERSTOOD_1 != null ? _UNDERSTOOD_1!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_2=" + (_UNDERSTOOD_2 != null ? _UNDERSTOOD_2!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_3=" + (_UNDERSTOOD_3 != null ? _UNDERSTOOD_3!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_4=" + (_UNDERSTOOD_4 != null ? _UNDERSTOOD_4!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_5=" + (_UNDERSTOOD_5 != null ? _UNDERSTOOD_5!.toString() : "null") + ", ");
    buffer.write("UNDERSTOOD_6=" + (_UNDERSTOOD_6 != null ? _UNDERSTOOD_6!.toString() : "null") + ", ");
    buffer.write("STRESSED_1=" + (_STRESSED_1 != null ? _STRESSED_1!.toString() : "null") + ", ");
    buffer.write("STRESSED_2=" + (_STRESSED_2 != null ? _STRESSED_2!.toString() : "null") + ", ");
    buffer.write("STRESSED_3=" + (_STRESSED_3 != null ? _STRESSED_3!.toString() : "null") + ", ");
    buffer.write("STRESSED_4=" + (_STRESSED_4 != null ? _STRESSED_4!.toString() : "null") + ", ");
    buffer.write("STRESSED_5=" + (_STRESSED_5 != null ? _STRESSED_5!.toString() : "null") + ", ");
    buffer.write("STRESSED_6=" + (_STRESSED_6 != null ? _STRESSED_6!.toString() : "null") + ", ");
    buffer.write("WHERE_YOU_ARE_1=" + "$_WHERE_YOU_ARE_1" + ", ");
    buffer.write("WHERE_YOU_ARE_2=" + "$_WHERE_YOU_ARE_2" + ", ");
    buffer.write("WHERE_YOU_ARE_3=" + "$_WHERE_YOU_ARE_3" + ", ");
    buffer.write("WHERE_YOU_ARE_4=" + "$_WHERE_YOU_ARE_4" + ", ");
    buffer.write("WHERE_YOU_ARE_5=" + "$_WHERE_YOU_ARE_5" + ", ");
    buffer.write("WHERE_YOU_ARE_6=" + "$_WHERE_YOU_ARE_6" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_1=" + "$_PEOPLE_AROUND_YOU_1" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_2=" + "$_PEOPLE_AROUND_YOU_2" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_3=" + "$_PEOPLE_AROUND_YOU_3" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_4=" + "$_PEOPLE_AROUND_YOU_4" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_5=" + "$_PEOPLE_AROUND_YOU_5" + ", ");
    buffer.write("PEOPLE_AROUND_YOU_6=" + "$_PEOPLE_AROUND_YOU_6" + ", ");
    buffer.write("DRINKS_1=" + (_DRINKS_1 != null ? _DRINKS_1!.toString() : "null") + ", ");
    buffer.write("DRINKS_2=" + (_DRINKS_2 != null ? _DRINKS_2!.toString() : "null") + ", ");
    buffer.write("DRINKS_3=" + (_DRINKS_3 != null ? _DRINKS_3!.toString() : "null") + ", ");
    buffer.write("DRINKS_4=" + (_DRINKS_4 != null ? _DRINKS_4!.toString() : "null") + ", ");
    buffer.write("DRINKS_5=" + (_DRINKS_5 != null ? _DRINKS_5!.toString() : "null") + ", ");
    buffer.write("DRINKS_6=" + (_DRINKS_6 != null ? _DRINKS_6!.toString() : "null") + ", ");
    buffer.write("STARTTIME=" + "$_STARTTIME" + ", ");
    buffer.write("ENDTIME=" + "$_ENDTIME" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Participants copyWith({String? STUDYCODE, int? PHYSICALLY_1, int? PHYSICALLY_2, int? PHYSICALLY_3, int? PHYSICALLY_4, int? PHYSICALLY_5, int? PHYSICALLY_6, int? EMOTIONALLY_1, int? EMOTIONALLY_2, int? EMOTIONALLY_3, int? EMOTIONALLY_4, int? EMOTIONALLY_5, int? EMOTIONALLY_6, int? INTENSITY_1, int? INTENSITY_2, int? INTENSITY_3, int? INTENSITY_4, int? INTENSITY_5, int? INTENSITY_6, int? LONELY_1, int? LONELY_2, int? LONELY_3, int? LONELY_4, int? LONELY_5, int? LONELY_6, int? LEFT_OUT_1, int? LEFT_OUT_2, int? LEFT_OUT_3, int? LEFT_OUT_4, int? LEFT_OUT_5, int? LEFT_OUT_6, int? SOCIAL_INTERACTION_1, int? SOCIAL_INTERACTION_2, int? SOCIAL_INTERACTION_3, int? SOCIAL_INTERACTION_4, int? SOCIAL_INTERACTION_5, int? SOCIAL_INTERACTION_6, int? UNDERSTOOD_1, int? UNDERSTOOD_2, int? UNDERSTOOD_3, int? UNDERSTOOD_4, int? UNDERSTOOD_5, int? UNDERSTOOD_6, int? STRESSED_1, int? STRESSED_2, int? STRESSED_3, int? STRESSED_4, int? STRESSED_5, int? STRESSED_6, String? WHERE_YOU_ARE_1, String? WHERE_YOU_ARE_2, String? WHERE_YOU_ARE_3, String? WHERE_YOU_ARE_4, String? WHERE_YOU_ARE_5, String? WHERE_YOU_ARE_6, String? PEOPLE_AROUND_YOU_1, String? PEOPLE_AROUND_YOU_2, String? PEOPLE_AROUND_YOU_3, String? PEOPLE_AROUND_YOU_4, String? PEOPLE_AROUND_YOU_5, String? PEOPLE_AROUND_YOU_6, int? DRINKS_1, int? DRINKS_2, int? DRINKS_3, int? DRINKS_4, int? DRINKS_5, int? DRINKS_6, String? STARTTIME, String? ENDTIME}) {
    return Participants._internal(
      id: id,
      STUDYCODE: STUDYCODE ?? this.STUDYCODE,
      PHYSICALLY_1: PHYSICALLY_1 ?? this.PHYSICALLY_1,
      PHYSICALLY_2: PHYSICALLY_2 ?? this.PHYSICALLY_2,
      PHYSICALLY_3: PHYSICALLY_3 ?? this.PHYSICALLY_3,
      PHYSICALLY_4: PHYSICALLY_4 ?? this.PHYSICALLY_4,
      PHYSICALLY_5: PHYSICALLY_5 ?? this.PHYSICALLY_5,
      PHYSICALLY_6: PHYSICALLY_6 ?? this.PHYSICALLY_6,
      EMOTIONALLY_1: EMOTIONALLY_1 ?? this.EMOTIONALLY_1,
      EMOTIONALLY_2: EMOTIONALLY_2 ?? this.EMOTIONALLY_2,
      EMOTIONALLY_3: EMOTIONALLY_3 ?? this.EMOTIONALLY_3,
      EMOTIONALLY_4: EMOTIONALLY_4 ?? this.EMOTIONALLY_4,
      EMOTIONALLY_5: EMOTIONALLY_5 ?? this.EMOTIONALLY_5,
      EMOTIONALLY_6: EMOTIONALLY_6 ?? this.EMOTIONALLY_6,
      INTENSITY_1: INTENSITY_1 ?? this.INTENSITY_1,
      INTENSITY_2: INTENSITY_2 ?? this.INTENSITY_2,
      INTENSITY_3: INTENSITY_3 ?? this.INTENSITY_3,
      INTENSITY_4: INTENSITY_4 ?? this.INTENSITY_4,
      INTENSITY_5: INTENSITY_5 ?? this.INTENSITY_5,
      INTENSITY_6: INTENSITY_6 ?? this.INTENSITY_6,
      LONELY_1: LONELY_1 ?? this.LONELY_1,
      LONELY_2: LONELY_2 ?? this.LONELY_2,
      LONELY_3: LONELY_3 ?? this.LONELY_3,
      LONELY_4: LONELY_4 ?? this.LONELY_4,
      LONELY_5: LONELY_5 ?? this.LONELY_5,
      LONELY_6: LONELY_6 ?? this.LONELY_6,
      LEFT_OUT_1: LEFT_OUT_1 ?? this.LEFT_OUT_1,
      LEFT_OUT_2: LEFT_OUT_2 ?? this.LEFT_OUT_2,
      LEFT_OUT_3: LEFT_OUT_3 ?? this.LEFT_OUT_3,
      LEFT_OUT_4: LEFT_OUT_4 ?? this.LEFT_OUT_4,
      LEFT_OUT_5: LEFT_OUT_5 ?? this.LEFT_OUT_5,
      LEFT_OUT_6: LEFT_OUT_6 ?? this.LEFT_OUT_6,
      SOCIAL_INTERACTION_1: SOCIAL_INTERACTION_1 ?? this.SOCIAL_INTERACTION_1,
      SOCIAL_INTERACTION_2: SOCIAL_INTERACTION_2 ?? this.SOCIAL_INTERACTION_2,
      SOCIAL_INTERACTION_3: SOCIAL_INTERACTION_3 ?? this.SOCIAL_INTERACTION_3,
      SOCIAL_INTERACTION_4: SOCIAL_INTERACTION_4 ?? this.SOCIAL_INTERACTION_4,
      SOCIAL_INTERACTION_5: SOCIAL_INTERACTION_5 ?? this.SOCIAL_INTERACTION_5,
      SOCIAL_INTERACTION_6: SOCIAL_INTERACTION_6 ?? this.SOCIAL_INTERACTION_6,
      UNDERSTOOD_1: UNDERSTOOD_1 ?? this.UNDERSTOOD_1,
      UNDERSTOOD_2: UNDERSTOOD_2 ?? this.UNDERSTOOD_2,
      UNDERSTOOD_3: UNDERSTOOD_3 ?? this.UNDERSTOOD_3,
      UNDERSTOOD_4: UNDERSTOOD_4 ?? this.UNDERSTOOD_4,
      UNDERSTOOD_5: UNDERSTOOD_5 ?? this.UNDERSTOOD_5,
      UNDERSTOOD_6: UNDERSTOOD_6 ?? this.UNDERSTOOD_6,
      STRESSED_1: STRESSED_1 ?? this.STRESSED_1,
      STRESSED_2: STRESSED_2 ?? this.STRESSED_2,
      STRESSED_3: STRESSED_3 ?? this.STRESSED_3,
      STRESSED_4: STRESSED_4 ?? this.STRESSED_4,
      STRESSED_5: STRESSED_5 ?? this.STRESSED_5,
      STRESSED_6: STRESSED_6 ?? this.STRESSED_6,
      WHERE_YOU_ARE_1: WHERE_YOU_ARE_1 ?? this.WHERE_YOU_ARE_1,
      WHERE_YOU_ARE_2: WHERE_YOU_ARE_2 ?? this.WHERE_YOU_ARE_2,
      WHERE_YOU_ARE_3: WHERE_YOU_ARE_3 ?? this.WHERE_YOU_ARE_3,
      WHERE_YOU_ARE_4: WHERE_YOU_ARE_4 ?? this.WHERE_YOU_ARE_4,
      WHERE_YOU_ARE_5: WHERE_YOU_ARE_5 ?? this.WHERE_YOU_ARE_5,
      WHERE_YOU_ARE_6: WHERE_YOU_ARE_6 ?? this.WHERE_YOU_ARE_6,
      PEOPLE_AROUND_YOU_1: PEOPLE_AROUND_YOU_1 ?? this.PEOPLE_AROUND_YOU_1,
      PEOPLE_AROUND_YOU_2: PEOPLE_AROUND_YOU_2 ?? this.PEOPLE_AROUND_YOU_2,
      PEOPLE_AROUND_YOU_3: PEOPLE_AROUND_YOU_3 ?? this.PEOPLE_AROUND_YOU_3,
      PEOPLE_AROUND_YOU_4: PEOPLE_AROUND_YOU_4 ?? this.PEOPLE_AROUND_YOU_4,
      PEOPLE_AROUND_YOU_5: PEOPLE_AROUND_YOU_5 ?? this.PEOPLE_AROUND_YOU_5,
      PEOPLE_AROUND_YOU_6: PEOPLE_AROUND_YOU_6 ?? this.PEOPLE_AROUND_YOU_6,
      DRINKS_1: DRINKS_1 ?? this.DRINKS_1,
      DRINKS_2: DRINKS_2 ?? this.DRINKS_2,
      DRINKS_3: DRINKS_3 ?? this.DRINKS_3,
      DRINKS_4: DRINKS_4 ?? this.DRINKS_4,
      DRINKS_5: DRINKS_5 ?? this.DRINKS_5,
      DRINKS_6: DRINKS_6 ?? this.DRINKS_6,
      STARTTIME: STARTTIME ?? this.STARTTIME,
      ENDTIME: ENDTIME ?? this.ENDTIME);
  }
  
  Participants copyWithModelFieldValues({
    ModelFieldValue<String>? STUDYCODE,
    ModelFieldValue<int?>? PHYSICALLY_1,
    ModelFieldValue<int?>? PHYSICALLY_2,
    ModelFieldValue<int?>? PHYSICALLY_3,
    ModelFieldValue<int?>? PHYSICALLY_4,
    ModelFieldValue<int?>? PHYSICALLY_5,
    ModelFieldValue<int?>? PHYSICALLY_6,
    ModelFieldValue<int?>? EMOTIONALLY_1,
    ModelFieldValue<int?>? EMOTIONALLY_2,
    ModelFieldValue<int?>? EMOTIONALLY_3,
    ModelFieldValue<int?>? EMOTIONALLY_4,
    ModelFieldValue<int?>? EMOTIONALLY_5,
    ModelFieldValue<int?>? EMOTIONALLY_6,
    ModelFieldValue<int?>? INTENSITY_1,
    ModelFieldValue<int?>? INTENSITY_2,
    ModelFieldValue<int?>? INTENSITY_3,
    ModelFieldValue<int?>? INTENSITY_4,
    ModelFieldValue<int?>? INTENSITY_5,
    ModelFieldValue<int?>? INTENSITY_6,
    ModelFieldValue<int?>? LONELY_1,
    ModelFieldValue<int?>? LONELY_2,
    ModelFieldValue<int?>? LONELY_3,
    ModelFieldValue<int?>? LONELY_4,
    ModelFieldValue<int?>? LONELY_5,
    ModelFieldValue<int?>? LONELY_6,
    ModelFieldValue<int?>? LEFT_OUT_1,
    ModelFieldValue<int?>? LEFT_OUT_2,
    ModelFieldValue<int?>? LEFT_OUT_3,
    ModelFieldValue<int?>? LEFT_OUT_4,
    ModelFieldValue<int?>? LEFT_OUT_5,
    ModelFieldValue<int?>? LEFT_OUT_6,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_1,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_2,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_3,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_4,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_5,
    ModelFieldValue<int?>? SOCIAL_INTERACTION_6,
    ModelFieldValue<int?>? UNDERSTOOD_1,
    ModelFieldValue<int?>? UNDERSTOOD_2,
    ModelFieldValue<int?>? UNDERSTOOD_3,
    ModelFieldValue<int?>? UNDERSTOOD_4,
    ModelFieldValue<int?>? UNDERSTOOD_5,
    ModelFieldValue<int?>? UNDERSTOOD_6,
    ModelFieldValue<int?>? STRESSED_1,
    ModelFieldValue<int?>? STRESSED_2,
    ModelFieldValue<int?>? STRESSED_3,
    ModelFieldValue<int?>? STRESSED_4,
    ModelFieldValue<int?>? STRESSED_5,
    ModelFieldValue<int?>? STRESSED_6,
    ModelFieldValue<String?>? WHERE_YOU_ARE_1,
    ModelFieldValue<String?>? WHERE_YOU_ARE_2,
    ModelFieldValue<String?>? WHERE_YOU_ARE_3,
    ModelFieldValue<String?>? WHERE_YOU_ARE_4,
    ModelFieldValue<String?>? WHERE_YOU_ARE_5,
    ModelFieldValue<String?>? WHERE_YOU_ARE_6,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_1,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_2,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_3,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_4,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_5,
    ModelFieldValue<String?>? PEOPLE_AROUND_YOU_6,
    ModelFieldValue<int?>? DRINKS_1,
    ModelFieldValue<int?>? DRINKS_2,
    ModelFieldValue<int?>? DRINKS_3,
    ModelFieldValue<int?>? DRINKS_4,
    ModelFieldValue<int?>? DRINKS_5,
    ModelFieldValue<int?>? DRINKS_6,
    ModelFieldValue<String?>? STARTTIME,
    ModelFieldValue<String?>? ENDTIME
  }) {
    return Participants._internal(
      id: id,
      STUDYCODE: STUDYCODE == null ? this.STUDYCODE : STUDYCODE.value,
      PHYSICALLY_1: PHYSICALLY_1 == null ? this.PHYSICALLY_1 : PHYSICALLY_1.value,
      PHYSICALLY_2: PHYSICALLY_2 == null ? this.PHYSICALLY_2 : PHYSICALLY_2.value,
      PHYSICALLY_3: PHYSICALLY_3 == null ? this.PHYSICALLY_3 : PHYSICALLY_3.value,
      PHYSICALLY_4: PHYSICALLY_4 == null ? this.PHYSICALLY_4 : PHYSICALLY_4.value,
      PHYSICALLY_5: PHYSICALLY_5 == null ? this.PHYSICALLY_5 : PHYSICALLY_5.value,
      PHYSICALLY_6: PHYSICALLY_6 == null ? this.PHYSICALLY_6 : PHYSICALLY_6.value,
      EMOTIONALLY_1: EMOTIONALLY_1 == null ? this.EMOTIONALLY_1 : EMOTIONALLY_1.value,
      EMOTIONALLY_2: EMOTIONALLY_2 == null ? this.EMOTIONALLY_2 : EMOTIONALLY_2.value,
      EMOTIONALLY_3: EMOTIONALLY_3 == null ? this.EMOTIONALLY_3 : EMOTIONALLY_3.value,
      EMOTIONALLY_4: EMOTIONALLY_4 == null ? this.EMOTIONALLY_4 : EMOTIONALLY_4.value,
      EMOTIONALLY_5: EMOTIONALLY_5 == null ? this.EMOTIONALLY_5 : EMOTIONALLY_5.value,
      EMOTIONALLY_6: EMOTIONALLY_6 == null ? this.EMOTIONALLY_6 : EMOTIONALLY_6.value,
      INTENSITY_1: INTENSITY_1 == null ? this.INTENSITY_1 : INTENSITY_1.value,
      INTENSITY_2: INTENSITY_2 == null ? this.INTENSITY_2 : INTENSITY_2.value,
      INTENSITY_3: INTENSITY_3 == null ? this.INTENSITY_3 : INTENSITY_3.value,
      INTENSITY_4: INTENSITY_4 == null ? this.INTENSITY_4 : INTENSITY_4.value,
      INTENSITY_5: INTENSITY_5 == null ? this.INTENSITY_5 : INTENSITY_5.value,
      INTENSITY_6: INTENSITY_6 == null ? this.INTENSITY_6 : INTENSITY_6.value,
      LONELY_1: LONELY_1 == null ? this.LONELY_1 : LONELY_1.value,
      LONELY_2: LONELY_2 == null ? this.LONELY_2 : LONELY_2.value,
      LONELY_3: LONELY_3 == null ? this.LONELY_3 : LONELY_3.value,
      LONELY_4: LONELY_4 == null ? this.LONELY_4 : LONELY_4.value,
      LONELY_5: LONELY_5 == null ? this.LONELY_5 : LONELY_5.value,
      LONELY_6: LONELY_6 == null ? this.LONELY_6 : LONELY_6.value,
      LEFT_OUT_1: LEFT_OUT_1 == null ? this.LEFT_OUT_1 : LEFT_OUT_1.value,
      LEFT_OUT_2: LEFT_OUT_2 == null ? this.LEFT_OUT_2 : LEFT_OUT_2.value,
      LEFT_OUT_3: LEFT_OUT_3 == null ? this.LEFT_OUT_3 : LEFT_OUT_3.value,
      LEFT_OUT_4: LEFT_OUT_4 == null ? this.LEFT_OUT_4 : LEFT_OUT_4.value,
      LEFT_OUT_5: LEFT_OUT_5 == null ? this.LEFT_OUT_5 : LEFT_OUT_5.value,
      LEFT_OUT_6: LEFT_OUT_6 == null ? this.LEFT_OUT_6 : LEFT_OUT_6.value,
      SOCIAL_INTERACTION_1: SOCIAL_INTERACTION_1 == null ? this.SOCIAL_INTERACTION_1 : SOCIAL_INTERACTION_1.value,
      SOCIAL_INTERACTION_2: SOCIAL_INTERACTION_2 == null ? this.SOCIAL_INTERACTION_2 : SOCIAL_INTERACTION_2.value,
      SOCIAL_INTERACTION_3: SOCIAL_INTERACTION_3 == null ? this.SOCIAL_INTERACTION_3 : SOCIAL_INTERACTION_3.value,
      SOCIAL_INTERACTION_4: SOCIAL_INTERACTION_4 == null ? this.SOCIAL_INTERACTION_4 : SOCIAL_INTERACTION_4.value,
      SOCIAL_INTERACTION_5: SOCIAL_INTERACTION_5 == null ? this.SOCIAL_INTERACTION_5 : SOCIAL_INTERACTION_5.value,
      SOCIAL_INTERACTION_6: SOCIAL_INTERACTION_6 == null ? this.SOCIAL_INTERACTION_6 : SOCIAL_INTERACTION_6.value,
      UNDERSTOOD_1: UNDERSTOOD_1 == null ? this.UNDERSTOOD_1 : UNDERSTOOD_1.value,
      UNDERSTOOD_2: UNDERSTOOD_2 == null ? this.UNDERSTOOD_2 : UNDERSTOOD_2.value,
      UNDERSTOOD_3: UNDERSTOOD_3 == null ? this.UNDERSTOOD_3 : UNDERSTOOD_3.value,
      UNDERSTOOD_4: UNDERSTOOD_4 == null ? this.UNDERSTOOD_4 : UNDERSTOOD_4.value,
      UNDERSTOOD_5: UNDERSTOOD_5 == null ? this.UNDERSTOOD_5 : UNDERSTOOD_5.value,
      UNDERSTOOD_6: UNDERSTOOD_6 == null ? this.UNDERSTOOD_6 : UNDERSTOOD_6.value,
      STRESSED_1: STRESSED_1 == null ? this.STRESSED_1 : STRESSED_1.value,
      STRESSED_2: STRESSED_2 == null ? this.STRESSED_2 : STRESSED_2.value,
      STRESSED_3: STRESSED_3 == null ? this.STRESSED_3 : STRESSED_3.value,
      STRESSED_4: STRESSED_4 == null ? this.STRESSED_4 : STRESSED_4.value,
      STRESSED_5: STRESSED_5 == null ? this.STRESSED_5 : STRESSED_5.value,
      STRESSED_6: STRESSED_6 == null ? this.STRESSED_6 : STRESSED_6.value,
      WHERE_YOU_ARE_1: WHERE_YOU_ARE_1 == null ? this.WHERE_YOU_ARE_1 : WHERE_YOU_ARE_1.value,
      WHERE_YOU_ARE_2: WHERE_YOU_ARE_2 == null ? this.WHERE_YOU_ARE_2 : WHERE_YOU_ARE_2.value,
      WHERE_YOU_ARE_3: WHERE_YOU_ARE_3 == null ? this.WHERE_YOU_ARE_3 : WHERE_YOU_ARE_3.value,
      WHERE_YOU_ARE_4: WHERE_YOU_ARE_4 == null ? this.WHERE_YOU_ARE_4 : WHERE_YOU_ARE_4.value,
      WHERE_YOU_ARE_5: WHERE_YOU_ARE_5 == null ? this.WHERE_YOU_ARE_5 : WHERE_YOU_ARE_5.value,
      WHERE_YOU_ARE_6: WHERE_YOU_ARE_6 == null ? this.WHERE_YOU_ARE_6 : WHERE_YOU_ARE_6.value,
      PEOPLE_AROUND_YOU_1: PEOPLE_AROUND_YOU_1 == null ? this.PEOPLE_AROUND_YOU_1 : PEOPLE_AROUND_YOU_1.value,
      PEOPLE_AROUND_YOU_2: PEOPLE_AROUND_YOU_2 == null ? this.PEOPLE_AROUND_YOU_2 : PEOPLE_AROUND_YOU_2.value,
      PEOPLE_AROUND_YOU_3: PEOPLE_AROUND_YOU_3 == null ? this.PEOPLE_AROUND_YOU_3 : PEOPLE_AROUND_YOU_3.value,
      PEOPLE_AROUND_YOU_4: PEOPLE_AROUND_YOU_4 == null ? this.PEOPLE_AROUND_YOU_4 : PEOPLE_AROUND_YOU_4.value,
      PEOPLE_AROUND_YOU_5: PEOPLE_AROUND_YOU_5 == null ? this.PEOPLE_AROUND_YOU_5 : PEOPLE_AROUND_YOU_5.value,
      PEOPLE_AROUND_YOU_6: PEOPLE_AROUND_YOU_6 == null ? this.PEOPLE_AROUND_YOU_6 : PEOPLE_AROUND_YOU_6.value,
      DRINKS_1: DRINKS_1 == null ? this.DRINKS_1 : DRINKS_1.value,
      DRINKS_2: DRINKS_2 == null ? this.DRINKS_2 : DRINKS_2.value,
      DRINKS_3: DRINKS_3 == null ? this.DRINKS_3 : DRINKS_3.value,
      DRINKS_4: DRINKS_4 == null ? this.DRINKS_4 : DRINKS_4.value,
      DRINKS_5: DRINKS_5 == null ? this.DRINKS_5 : DRINKS_5.value,
      DRINKS_6: DRINKS_6 == null ? this.DRINKS_6 : DRINKS_6.value,
      STARTTIME: STARTTIME == null ? this.STARTTIME : STARTTIME.value,
      ENDTIME: ENDTIME == null ? this.ENDTIME : ENDTIME.value
    );
  }
  
  Participants.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _STUDYCODE = json['STUDYCODE'],
      _PHYSICALLY_1 = (json['PHYSICALLY_1'] as num?)?.toInt(),
      _PHYSICALLY_2 = (json['PHYSICALLY_2'] as num?)?.toInt(),
      _PHYSICALLY_3 = (json['PHYSICALLY_3'] as num?)?.toInt(),
      _PHYSICALLY_4 = (json['PHYSICALLY_4'] as num?)?.toInt(),
      _PHYSICALLY_5 = (json['PHYSICALLY_5'] as num?)?.toInt(),
      _PHYSICALLY_6 = (json['PHYSICALLY_6'] as num?)?.toInt(),
      _EMOTIONALLY_1 = (json['EMOTIONALLY_1'] as num?)?.toInt(),
      _EMOTIONALLY_2 = (json['EMOTIONALLY_2'] as num?)?.toInt(),
      _EMOTIONALLY_3 = (json['EMOTIONALLY_3'] as num?)?.toInt(),
      _EMOTIONALLY_4 = (json['EMOTIONALLY_4'] as num?)?.toInt(),
      _EMOTIONALLY_5 = (json['EMOTIONALLY_5'] as num?)?.toInt(),
      _EMOTIONALLY_6 = (json['EMOTIONALLY_6'] as num?)?.toInt(),
      _INTENSITY_1 = (json['INTENSITY_1'] as num?)?.toInt(),
      _INTENSITY_2 = (json['INTENSITY_2'] as num?)?.toInt(),
      _INTENSITY_3 = (json['INTENSITY_3'] as num?)?.toInt(),
      _INTENSITY_4 = (json['INTENSITY_4'] as num?)?.toInt(),
      _INTENSITY_5 = (json['INTENSITY_5'] as num?)?.toInt(),
      _INTENSITY_6 = (json['INTENSITY_6'] as num?)?.toInt(),
      _LONELY_1 = (json['LONELY_1'] as num?)?.toInt(),
      _LONELY_2 = (json['LONELY_2'] as num?)?.toInt(),
      _LONELY_3 = (json['LONELY_3'] as num?)?.toInt(),
      _LONELY_4 = (json['LONELY_4'] as num?)?.toInt(),
      _LONELY_5 = (json['LONELY_5'] as num?)?.toInt(),
      _LONELY_6 = (json['LONELY_6'] as num?)?.toInt(),
      _LEFT_OUT_1 = (json['LEFT_OUT_1'] as num?)?.toInt(),
      _LEFT_OUT_2 = (json['LEFT_OUT_2'] as num?)?.toInt(),
      _LEFT_OUT_3 = (json['LEFT_OUT_3'] as num?)?.toInt(),
      _LEFT_OUT_4 = (json['LEFT_OUT_4'] as num?)?.toInt(),
      _LEFT_OUT_5 = (json['LEFT_OUT_5'] as num?)?.toInt(),
      _LEFT_OUT_6 = (json['LEFT_OUT_6'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_1 = (json['SOCIAL_INTERACTION_1'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_2 = (json['SOCIAL_INTERACTION_2'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_3 = (json['SOCIAL_INTERACTION_3'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_4 = (json['SOCIAL_INTERACTION_4'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_5 = (json['SOCIAL_INTERACTION_5'] as num?)?.toInt(),
      _SOCIAL_INTERACTION_6 = (json['SOCIAL_INTERACTION_6'] as num?)?.toInt(),
      _UNDERSTOOD_1 = (json['UNDERSTOOD_1'] as num?)?.toInt(),
      _UNDERSTOOD_2 = (json['UNDERSTOOD_2'] as num?)?.toInt(),
      _UNDERSTOOD_3 = (json['UNDERSTOOD_3'] as num?)?.toInt(),
      _UNDERSTOOD_4 = (json['UNDERSTOOD_4'] as num?)?.toInt(),
      _UNDERSTOOD_5 = (json['UNDERSTOOD_5'] as num?)?.toInt(),
      _UNDERSTOOD_6 = (json['UNDERSTOOD_6'] as num?)?.toInt(),
      _STRESSED_1 = (json['STRESSED_1'] as num?)?.toInt(),
      _STRESSED_2 = (json['STRESSED_2'] as num?)?.toInt(),
      _STRESSED_3 = (json['STRESSED_3'] as num?)?.toInt(),
      _STRESSED_4 = (json['STRESSED_4'] as num?)?.toInt(),
      _STRESSED_5 = (json['STRESSED_5'] as num?)?.toInt(),
      _STRESSED_6 = (json['STRESSED_6'] as num?)?.toInt(),
      _WHERE_YOU_ARE_1 = json['WHERE_YOU_ARE_1'],
      _WHERE_YOU_ARE_2 = json['WHERE_YOU_ARE_2'],
      _WHERE_YOU_ARE_3 = json['WHERE_YOU_ARE_3'],
      _WHERE_YOU_ARE_4 = json['WHERE_YOU_ARE_4'],
      _WHERE_YOU_ARE_5 = json['WHERE_YOU_ARE_5'],
      _WHERE_YOU_ARE_6 = json['WHERE_YOU_ARE_6'],
      _PEOPLE_AROUND_YOU_1 = json['PEOPLE_AROUND_YOU_1'],
      _PEOPLE_AROUND_YOU_2 = json['PEOPLE_AROUND_YOU_2'],
      _PEOPLE_AROUND_YOU_3 = json['PEOPLE_AROUND_YOU_3'],
      _PEOPLE_AROUND_YOU_4 = json['PEOPLE_AROUND_YOU_4'],
      _PEOPLE_AROUND_YOU_5 = json['PEOPLE_AROUND_YOU_5'],
      _PEOPLE_AROUND_YOU_6 = json['PEOPLE_AROUND_YOU_6'],
      _DRINKS_1 = (json['DRINKS_1'] as num?)?.toInt(),
      _DRINKS_2 = (json['DRINKS_2'] as num?)?.toInt(),
      _DRINKS_3 = (json['DRINKS_3'] as num?)?.toInt(),
      _DRINKS_4 = (json['DRINKS_4'] as num?)?.toInt(),
      _DRINKS_5 = (json['DRINKS_5'] as num?)?.toInt(),
      _DRINKS_6 = (json['DRINKS_6'] as num?)?.toInt(),
      _STARTTIME = json['STARTTIME'],
      _ENDTIME = json['ENDTIME'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'STUDYCODE': _STUDYCODE, 'PHYSICALLY_1': _PHYSICALLY_1, 'PHYSICALLY_2': _PHYSICALLY_2, 'PHYSICALLY_3': _PHYSICALLY_3, 'PHYSICALLY_4': _PHYSICALLY_4, 'PHYSICALLY_5': _PHYSICALLY_5, 'PHYSICALLY_6': _PHYSICALLY_6, 'EMOTIONALLY_1': _EMOTIONALLY_1, 'EMOTIONALLY_2': _EMOTIONALLY_2, 'EMOTIONALLY_3': _EMOTIONALLY_3, 'EMOTIONALLY_4': _EMOTIONALLY_4, 'EMOTIONALLY_5': _EMOTIONALLY_5, 'EMOTIONALLY_6': _EMOTIONALLY_6, 'INTENSITY_1': _INTENSITY_1, 'INTENSITY_2': _INTENSITY_2, 'INTENSITY_3': _INTENSITY_3, 'INTENSITY_4': _INTENSITY_4, 'INTENSITY_5': _INTENSITY_5, 'INTENSITY_6': _INTENSITY_6, 'LONELY_1': _LONELY_1, 'LONELY_2': _LONELY_2, 'LONELY_3': _LONELY_3, 'LONELY_4': _LONELY_4, 'LONELY_5': _LONELY_5, 'LONELY_6': _LONELY_6, 'LEFT_OUT_1': _LEFT_OUT_1, 'LEFT_OUT_2': _LEFT_OUT_2, 'LEFT_OUT_3': _LEFT_OUT_3, 'LEFT_OUT_4': _LEFT_OUT_4, 'LEFT_OUT_5': _LEFT_OUT_5, 'LEFT_OUT_6': _LEFT_OUT_6, 'SOCIAL_INTERACTION_1': _SOCIAL_INTERACTION_1, 'SOCIAL_INTERACTION_2': _SOCIAL_INTERACTION_2, 'SOCIAL_INTERACTION_3': _SOCIAL_INTERACTION_3, 'SOCIAL_INTERACTION_4': _SOCIAL_INTERACTION_4, 'SOCIAL_INTERACTION_5': _SOCIAL_INTERACTION_5, 'SOCIAL_INTERACTION_6': _SOCIAL_INTERACTION_6, 'UNDERSTOOD_1': _UNDERSTOOD_1, 'UNDERSTOOD_2': _UNDERSTOOD_2, 'UNDERSTOOD_3': _UNDERSTOOD_3, 'UNDERSTOOD_4': _UNDERSTOOD_4, 'UNDERSTOOD_5': _UNDERSTOOD_5, 'UNDERSTOOD_6': _UNDERSTOOD_6, 'STRESSED_1': _STRESSED_1, 'STRESSED_2': _STRESSED_2, 'STRESSED_3': _STRESSED_3, 'STRESSED_4': _STRESSED_4, 'STRESSED_5': _STRESSED_5, 'STRESSED_6': _STRESSED_6, 'WHERE_YOU_ARE_1': _WHERE_YOU_ARE_1, 'WHERE_YOU_ARE_2': _WHERE_YOU_ARE_2, 'WHERE_YOU_ARE_3': _WHERE_YOU_ARE_3, 'WHERE_YOU_ARE_4': _WHERE_YOU_ARE_4, 'WHERE_YOU_ARE_5': _WHERE_YOU_ARE_5, 'WHERE_YOU_ARE_6': _WHERE_YOU_ARE_6, 'PEOPLE_AROUND_YOU_1': _PEOPLE_AROUND_YOU_1, 'PEOPLE_AROUND_YOU_2': _PEOPLE_AROUND_YOU_2, 'PEOPLE_AROUND_YOU_3': _PEOPLE_AROUND_YOU_3, 'PEOPLE_AROUND_YOU_4': _PEOPLE_AROUND_YOU_4, 'PEOPLE_AROUND_YOU_5': _PEOPLE_AROUND_YOU_5, 'PEOPLE_AROUND_YOU_6': _PEOPLE_AROUND_YOU_6, 'DRINKS_1': _DRINKS_1, 'DRINKS_2': _DRINKS_2, 'DRINKS_3': _DRINKS_3, 'DRINKS_4': _DRINKS_4, 'DRINKS_5': _DRINKS_5, 'DRINKS_6': _DRINKS_6, 'STARTTIME': _STARTTIME, 'ENDTIME': _ENDTIME, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'STUDYCODE': _STUDYCODE,
    'PHYSICALLY_1': _PHYSICALLY_1,
    'PHYSICALLY_2': _PHYSICALLY_2,
    'PHYSICALLY_3': _PHYSICALLY_3,
    'PHYSICALLY_4': _PHYSICALLY_4,
    'PHYSICALLY_5': _PHYSICALLY_5,
    'PHYSICALLY_6': _PHYSICALLY_6,
    'EMOTIONALLY_1': _EMOTIONALLY_1,
    'EMOTIONALLY_2': _EMOTIONALLY_2,
    'EMOTIONALLY_3': _EMOTIONALLY_3,
    'EMOTIONALLY_4': _EMOTIONALLY_4,
    'EMOTIONALLY_5': _EMOTIONALLY_5,
    'EMOTIONALLY_6': _EMOTIONALLY_6,
    'INTENSITY_1': _INTENSITY_1,
    'INTENSITY_2': _INTENSITY_2,
    'INTENSITY_3': _INTENSITY_3,
    'INTENSITY_4': _INTENSITY_4,
    'INTENSITY_5': _INTENSITY_5,
    'INTENSITY_6': _INTENSITY_6,
    'LONELY_1': _LONELY_1,
    'LONELY_2': _LONELY_2,
    'LONELY_3': _LONELY_3,
    'LONELY_4': _LONELY_4,
    'LONELY_5': _LONELY_5,
    'LONELY_6': _LONELY_6,
    'LEFT_OUT_1': _LEFT_OUT_1,
    'LEFT_OUT_2': _LEFT_OUT_2,
    'LEFT_OUT_3': _LEFT_OUT_3,
    'LEFT_OUT_4': _LEFT_OUT_4,
    'LEFT_OUT_5': _LEFT_OUT_5,
    'LEFT_OUT_6': _LEFT_OUT_6,
    'SOCIAL_INTERACTION_1': _SOCIAL_INTERACTION_1,
    'SOCIAL_INTERACTION_2': _SOCIAL_INTERACTION_2,
    'SOCIAL_INTERACTION_3': _SOCIAL_INTERACTION_3,
    'SOCIAL_INTERACTION_4': _SOCIAL_INTERACTION_4,
    'SOCIAL_INTERACTION_5': _SOCIAL_INTERACTION_5,
    'SOCIAL_INTERACTION_6': _SOCIAL_INTERACTION_6,
    'UNDERSTOOD_1': _UNDERSTOOD_1,
    'UNDERSTOOD_2': _UNDERSTOOD_2,
    'UNDERSTOOD_3': _UNDERSTOOD_3,
    'UNDERSTOOD_4': _UNDERSTOOD_4,
    'UNDERSTOOD_5': _UNDERSTOOD_5,
    'UNDERSTOOD_6': _UNDERSTOOD_6,
    'STRESSED_1': _STRESSED_1,
    'STRESSED_2': _STRESSED_2,
    'STRESSED_3': _STRESSED_3,
    'STRESSED_4': _STRESSED_4,
    'STRESSED_5': _STRESSED_5,
    'STRESSED_6': _STRESSED_6,
    'WHERE_YOU_ARE_1': _WHERE_YOU_ARE_1,
    'WHERE_YOU_ARE_2': _WHERE_YOU_ARE_2,
    'WHERE_YOU_ARE_3': _WHERE_YOU_ARE_3,
    'WHERE_YOU_ARE_4': _WHERE_YOU_ARE_4,
    'WHERE_YOU_ARE_5': _WHERE_YOU_ARE_5,
    'WHERE_YOU_ARE_6': _WHERE_YOU_ARE_6,
    'PEOPLE_AROUND_YOU_1': _PEOPLE_AROUND_YOU_1,
    'PEOPLE_AROUND_YOU_2': _PEOPLE_AROUND_YOU_2,
    'PEOPLE_AROUND_YOU_3': _PEOPLE_AROUND_YOU_3,
    'PEOPLE_AROUND_YOU_4': _PEOPLE_AROUND_YOU_4,
    'PEOPLE_AROUND_YOU_5': _PEOPLE_AROUND_YOU_5,
    'PEOPLE_AROUND_YOU_6': _PEOPLE_AROUND_YOU_6,
    'DRINKS_1': _DRINKS_1,
    'DRINKS_2': _DRINKS_2,
    'DRINKS_3': _DRINKS_3,
    'DRINKS_4': _DRINKS_4,
    'DRINKS_5': _DRINKS_5,
    'DRINKS_6': _DRINKS_6,
    'STARTTIME': _STARTTIME,
    'ENDTIME': _ENDTIME,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ParticipantsModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ParticipantsModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final STUDYCODE_ = amplify_core.QueryField(fieldName: "STUDYCODE");
  static final PHYSICALLY_1_ = amplify_core.QueryField(fieldName: "PHYSICALLY_1");
  static final PHYSICALLY_2_ = amplify_core.QueryField(fieldName: "PHYSICALLY_2");
  static final PHYSICALLY_3_ = amplify_core.QueryField(fieldName: "PHYSICALLY_3");
  static final PHYSICALLY_4_ = amplify_core.QueryField(fieldName: "PHYSICALLY_4");
  static final PHYSICALLY_5_ = amplify_core.QueryField(fieldName: "PHYSICALLY_5");
  static final PHYSICALLY_6_ = amplify_core.QueryField(fieldName: "PHYSICALLY_6");
  static final EMOTIONALLY_1_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_1");
  static final EMOTIONALLY_2_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_2");
  static final EMOTIONALLY_3_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_3");
  static final EMOTIONALLY_4_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_4");
  static final EMOTIONALLY_5_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_5");
  static final EMOTIONALLY_6_ = amplify_core.QueryField(fieldName: "EMOTIONALLY_6");
  static final INTENSITY_1_ = amplify_core.QueryField(fieldName: "INTENSITY_1");
  static final INTENSITY_2_ = amplify_core.QueryField(fieldName: "INTENSITY_2");
  static final INTENSITY_3_ = amplify_core.QueryField(fieldName: "INTENSITY_3");
  static final INTENSITY_4_ = amplify_core.QueryField(fieldName: "INTENSITY_4");
  static final INTENSITY_5_ = amplify_core.QueryField(fieldName: "INTENSITY_5");
  static final INTENSITY_6_ = amplify_core.QueryField(fieldName: "INTENSITY_6");
  static final LONELY_1_ = amplify_core.QueryField(fieldName: "LONELY_1");
  static final LONELY_2_ = amplify_core.QueryField(fieldName: "LONELY_2");
  static final LONELY_3_ = amplify_core.QueryField(fieldName: "LONELY_3");
  static final LONELY_4_ = amplify_core.QueryField(fieldName: "LONELY_4");
  static final LONELY_5_ = amplify_core.QueryField(fieldName: "LONELY_5");
  static final LONELY_6_ = amplify_core.QueryField(fieldName: "LONELY_6");
  static final LEFT_OUT_1_ = amplify_core.QueryField(fieldName: "LEFT_OUT_1");
  static final LEFT_OUT_2_ = amplify_core.QueryField(fieldName: "LEFT_OUT_2");
  static final LEFT_OUT_3_ = amplify_core.QueryField(fieldName: "LEFT_OUT_3");
  static final LEFT_OUT_4_ = amplify_core.QueryField(fieldName: "LEFT_OUT_4");
  static final LEFT_OUT_5_ = amplify_core.QueryField(fieldName: "LEFT_OUT_5");
  static final LEFT_OUT_6_ = amplify_core.QueryField(fieldName: "LEFT_OUT_6");
  static final SOCIAL_INTERACTION_1_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_1");
  static final SOCIAL_INTERACTION_2_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_2");
  static final SOCIAL_INTERACTION_3_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_3");
  static final SOCIAL_INTERACTION_4_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_4");
  static final SOCIAL_INTERACTION_5_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_5");
  static final SOCIAL_INTERACTION_6_ = amplify_core.QueryField(fieldName: "SOCIAL_INTERACTION_6");
  static final UNDERSTOOD_1_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_1");
  static final UNDERSTOOD_2_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_2");
  static final UNDERSTOOD_3_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_3");
  static final UNDERSTOOD_4_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_4");
  static final UNDERSTOOD_5_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_5");
  static final UNDERSTOOD_6_ = amplify_core.QueryField(fieldName: "UNDERSTOOD_6");
  static final STRESSED_1_ = amplify_core.QueryField(fieldName: "STRESSED_1");
  static final STRESSED_2_ = amplify_core.QueryField(fieldName: "STRESSED_2");
  static final STRESSED_3_ = amplify_core.QueryField(fieldName: "STRESSED_3");
  static final STRESSED_4_ = amplify_core.QueryField(fieldName: "STRESSED_4");
  static final STRESSED_5_ = amplify_core.QueryField(fieldName: "STRESSED_5");
  static final STRESSED_6_ = amplify_core.QueryField(fieldName: "STRESSED_6");
  static final WHERE_YOU_ARE_1_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_1");
  static final WHERE_YOU_ARE_2_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_2");
  static final WHERE_YOU_ARE_3_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_3");
  static final WHERE_YOU_ARE_4_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_4");
  static final WHERE_YOU_ARE_5_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_5");
  static final WHERE_YOU_ARE_6_ = amplify_core.QueryField(fieldName: "WHERE_YOU_ARE_6");
  static final PEOPLE_AROUND_YOU_1_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_1");
  static final PEOPLE_AROUND_YOU_2_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_2");
  static final PEOPLE_AROUND_YOU_3_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_3");
  static final PEOPLE_AROUND_YOU_4_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_4");
  static final PEOPLE_AROUND_YOU_5_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_5");
  static final PEOPLE_AROUND_YOU_6_ = amplify_core.QueryField(fieldName: "PEOPLE_AROUND_YOU_6");
  static final DRINKS_1_ = amplify_core.QueryField(fieldName: "DRINKS_1");
  static final DRINKS_2_ = amplify_core.QueryField(fieldName: "DRINKS_2");
  static final DRINKS_3_ = amplify_core.QueryField(fieldName: "DRINKS_3");
  static final DRINKS_4_ = amplify_core.QueryField(fieldName: "DRINKS_4");
  static final DRINKS_5_ = amplify_core.QueryField(fieldName: "DRINKS_5");
  static final DRINKS_6_ = amplify_core.QueryField(fieldName: "DRINKS_6");
  static final STARTTIME_ = amplify_core.QueryField(fieldName: "STARTTIME");
  static final ENDTIME_ = amplify_core.QueryField(fieldName: "ENDTIME");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Participants";
    modelSchemaDefinition.pluralName = "Participants";
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STUDYCODE_,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PHYSICALLY_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.EMOTIONALLY_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.INTENSITY_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LONELY_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.LEFT_OUT_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.SOCIAL_INTERACTION_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.UNDERSTOOD_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STRESSED_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.WHERE_YOU_ARE_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.PEOPLE_AROUND_YOU_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_1_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_2_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_3_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_4_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_5_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.DRINKS_6_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.STARTTIME_,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Participants.ENDTIME_,
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

class _ParticipantsModelType extends amplify_core.ModelType<Participants> {
  const _ParticipantsModelType();
  
  @override
  Participants fromJson(Map<String, dynamic> jsonData) {
    return Participants.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Participants';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Participants] in your schema.
 */
class ParticipantsModelIdentifier implements amplify_core.ModelIdentifier<Participants> {
  final String id;

  /** Create an instance of ParticipantsModelIdentifier using [id] the primary key. */
  const ParticipantsModelIdentifier({
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
  String toString() => 'ParticipantsModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ParticipantsModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}