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


/** This is an auto generated class representing the ParticipantsDev type in your schema. */
class ParticipantsDev extends amplify_core.Model {
  static const classType = const _ParticipantsDevModelType();
  final String id;
  final int? _physically_1;
  final int? _physically_2;
  final int? _physically_3;
  final int? _physically_4;
  final int? _physically_5;
  final int? _physically_6;
  final int? _emotionally_1;
  final int? _emotionally_2;
  final int? _emotionally_3;
  final int? _emotionally_4;
  final int? _emotionally_5;
  final int? _emotionally_6;
  final int? _intensity_1;
  final int? _intensity_2;
  final int? _intensity_3;
  final int? _intensity_4;
  final int? _intensity_5;
  final int? _intensity_6;
  final int? _lonely_1;
  final int? _lonely_2;
  final int? _lonely_3;
  final int? _lonely_4;
  final int? _lonely_5;
  final int? _lonely_6;
  final int? _left_out_1;
  final int? _left_out_2;
  final int? _left_out_3;
  final int? _left_out_4;
  final int? _left_out_5;
  final int? _left_out_6;
  final int? _social_interaction_1;
  final int? _social_interaction_2;
  final int? _social_interaction_3;
  final int? _social_interaction_4;
  final int? _social_interaction_5;
  final int? _social_interaction_6;
  final int? _understood_1;
  final int? _understood_2;
  final int? _understood_3;
  final int? _understood_4;
  final int? _understood_5;
  final int? _understood_6;
  final int? _stressed_1;
  final int? _stressed_2;
  final int? _stressed_3;
  final int? _stressed_4;
  final int? _stressed_5;
  final int? _stressed_6;
  final String? _where_you_are_1;
  final String? _where_you_are_2;
  final String? _where_you_are_3;
  final String? _where_you_are_4;
  final String? _where_you_are_5;
  final String? _where_you_are_6;
  final String? _people_around_you_1;
  final String? _people_around_you_2;
  final String? _people_around_you_3;
  final String? _people_around_you_4;
  final String? _people_around_you_5;
  final String? _people_around_you_6;
  final String? _starttime_1;
  final String? _starttime_2;
  final String? _starttime_3;
  final String? _starttime_4;
  final String? _starttime_5;
  final String? _starttime_6;
  final String? _endtime_1;
  final String? _endtime_2;
  final String? _endtime_3;
  final String? _endtime_4;
  final String? _endtime_5;
  final String? _endtime_6;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ParticipantsDevModelIdentifier get modelIdentifier {
      return ParticipantsDevModelIdentifier(
        id: id
      );
  }
  
  int? get physically_1 {
    return _physically_1;
  }
  
  int? get physically_2 {
    return _physically_2;
  }
  
  int? get physically_3 {
    return _physically_3;
  }
  
  int? get physically_4 {
    return _physically_4;
  }
  
  int? get physically_5 {
    return _physically_5;
  }
  
  int? get physically_6 {
    return _physically_6;
  }
  
  int? get emotionally_1 {
    return _emotionally_1;
  }
  
  int? get emotionally_2 {
    return _emotionally_2;
  }
  
  int? get emotionally_3 {
    return _emotionally_3;
  }
  
  int? get emotionally_4 {
    return _emotionally_4;
  }
  
  int? get emotionally_5 {
    return _emotionally_5;
  }
  
  int? get emotionally_6 {
    return _emotionally_6;
  }
  
  int? get intensity_1 {
    return _intensity_1;
  }
  
  int? get intensity_2 {
    return _intensity_2;
  }
  
  int? get intensity_3 {
    return _intensity_3;
  }
  
  int? get intensity_4 {
    return _intensity_4;
  }
  
  int? get intensity_5 {
    return _intensity_5;
  }
  
  int? get intensity_6 {
    return _intensity_6;
  }
  
  int? get lonely_1 {
    return _lonely_1;
  }
  
  int? get lonely_2 {
    return _lonely_2;
  }
  
  int? get lonely_3 {
    return _lonely_3;
  }
  
  int? get lonely_4 {
    return _lonely_4;
  }
  
  int? get lonely_5 {
    return _lonely_5;
  }
  
  int? get lonely_6 {
    return _lonely_6;
  }
  
  int? get left_out_1 {
    return _left_out_1;
  }
  
  int? get left_out_2 {
    return _left_out_2;
  }
  
  int? get left_out_3 {
    return _left_out_3;
  }
  
  int? get left_out_4 {
    return _left_out_4;
  }
  
  int? get left_out_5 {
    return _left_out_5;
  }
  
  int? get left_out_6 {
    return _left_out_6;
  }
  
  int? get social_interaction_1 {
    return _social_interaction_1;
  }
  
  int? get social_interaction_2 {
    return _social_interaction_2;
  }
  
  int? get social_interaction_3 {
    return _social_interaction_3;
  }
  
  int? get social_interaction_4 {
    return _social_interaction_4;
  }
  
  int? get social_interaction_5 {
    return _social_interaction_5;
  }
  
  int? get social_interaction_6 {
    return _social_interaction_6;
  }
  
  int? get understood_1 {
    return _understood_1;
  }
  
  int? get understood_2 {
    return _understood_2;
  }
  
  int? get understood_3 {
    return _understood_3;
  }
  
  int? get understood_4 {
    return _understood_4;
  }
  
  int? get understood_5 {
    return _understood_5;
  }
  
  int? get understood_6 {
    return _understood_6;
  }
  
  int? get stressed_1 {
    return _stressed_1;
  }
  
  int? get stressed_2 {
    return _stressed_2;
  }
  
  int? get stressed_3 {
    return _stressed_3;
  }
  
  int? get stressed_4 {
    return _stressed_4;
  }
  
  int? get stressed_5 {
    return _stressed_5;
  }
  
  int? get stressed_6 {
    return _stressed_6;
  }
  
  String? get where_you_are_1 {
    return _where_you_are_1;
  }
  
  String? get where_you_are_2 {
    return _where_you_are_2;
  }
  
  String? get where_you_are_3 {
    return _where_you_are_3;
  }
  
  String? get where_you_are_4 {
    return _where_you_are_4;
  }
  
  String? get where_you_are_5 {
    return _where_you_are_5;
  }
  
  String? get where_you_are_6 {
    return _where_you_are_6;
  }
  
  String? get people_around_you_1 {
    return _people_around_you_1;
  }
  
  String? get people_around_you_2 {
    return _people_around_you_2;
  }
  
  String? get people_around_you_3 {
    return _people_around_you_3;
  }
  
  String? get people_around_you_4 {
    return _people_around_you_4;
  }
  
  String? get people_around_you_5 {
    return _people_around_you_5;
  }
  
  String? get people_around_you_6 {
    return _people_around_you_6;
  }
  
  String? get starttime_1 {
    return _starttime_1;
  }
  
  String? get starttime_2 {
    return _starttime_2;
  }
  
  String? get starttime_3 {
    return _starttime_3;
  }
  
  String? get starttime_4 {
    return _starttime_4;
  }
  
  String? get starttime_5 {
    return _starttime_5;
  }
  
  String? get starttime_6 {
    return _starttime_6;
  }
  
  String? get endtime_1 {
    return _endtime_1;
  }
  
  String? get endtime_2 {
    return _endtime_2;
  }
  
  String? get endtime_3 {
    return _endtime_3;
  }
  
  String? get endtime_4 {
    return _endtime_4;
  }
  
  String? get endtime_5 {
    return _endtime_5;
  }
  
  String? get endtime_6 {
    return _endtime_6;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const ParticipantsDev._internal({required this.id, physically_1, physically_2, physically_3, physically_4, physically_5, physically_6, emotionally_1, emotionally_2, emotionally_3, emotionally_4, emotionally_5, emotionally_6, intensity_1, intensity_2, intensity_3, intensity_4, intensity_5, intensity_6, lonely_1, lonely_2, lonely_3, lonely_4, lonely_5, lonely_6, left_out_1, left_out_2, left_out_3, left_out_4, left_out_5, left_out_6, social_interaction_1, social_interaction_2, social_interaction_3, social_interaction_4, social_interaction_5, social_interaction_6, understood_1, understood_2, understood_3, understood_4, understood_5, understood_6, stressed_1, stressed_2, stressed_3, stressed_4, stressed_5, stressed_6, where_you_are_1, where_you_are_2, where_you_are_3, where_you_are_4, where_you_are_5, where_you_are_6, people_around_you_1, people_around_you_2, people_around_you_3, people_around_you_4, people_around_you_5, people_around_you_6, starttime_1, starttime_2, starttime_3, starttime_4, starttime_5, starttime_6, endtime_1, endtime_2, endtime_3, endtime_4, endtime_5, endtime_6, createdAt, updatedAt}): _physically_1 = physically_1, _physically_2 = physically_2, _physically_3 = physically_3, _physically_4 = physically_4, _physically_5 = physically_5, _physically_6 = physically_6, _emotionally_1 = emotionally_1, _emotionally_2 = emotionally_2, _emotionally_3 = emotionally_3, _emotionally_4 = emotionally_4, _emotionally_5 = emotionally_5, _emotionally_6 = emotionally_6, _intensity_1 = intensity_1, _intensity_2 = intensity_2, _intensity_3 = intensity_3, _intensity_4 = intensity_4, _intensity_5 = intensity_5, _intensity_6 = intensity_6, _lonely_1 = lonely_1, _lonely_2 = lonely_2, _lonely_3 = lonely_3, _lonely_4 = lonely_4, _lonely_5 = lonely_5, _lonely_6 = lonely_6, _left_out_1 = left_out_1, _left_out_2 = left_out_2, _left_out_3 = left_out_3, _left_out_4 = left_out_4, _left_out_5 = left_out_5, _left_out_6 = left_out_6, _social_interaction_1 = social_interaction_1, _social_interaction_2 = social_interaction_2, _social_interaction_3 = social_interaction_3, _social_interaction_4 = social_interaction_4, _social_interaction_5 = social_interaction_5, _social_interaction_6 = social_interaction_6, _understood_1 = understood_1, _understood_2 = understood_2, _understood_3 = understood_3, _understood_4 = understood_4, _understood_5 = understood_5, _understood_6 = understood_6, _stressed_1 = stressed_1, _stressed_2 = stressed_2, _stressed_3 = stressed_3, _stressed_4 = stressed_4, _stressed_5 = stressed_5, _stressed_6 = stressed_6, _where_you_are_1 = where_you_are_1, _where_you_are_2 = where_you_are_2, _where_you_are_3 = where_you_are_3, _where_you_are_4 = where_you_are_4, _where_you_are_5 = where_you_are_5, _where_you_are_6 = where_you_are_6, _people_around_you_1 = people_around_you_1, _people_around_you_2 = people_around_you_2, _people_around_you_3 = people_around_you_3, _people_around_you_4 = people_around_you_4, _people_around_you_5 = people_around_you_5, _people_around_you_6 = people_around_you_6, _starttime_1 = starttime_1, _starttime_2 = starttime_2, _starttime_3 = starttime_3, _starttime_4 = starttime_4, _starttime_5 = starttime_5, _starttime_6 = starttime_6, _endtime_1 = endtime_1, _endtime_2 = endtime_2, _endtime_3 = endtime_3, _endtime_4 = endtime_4, _endtime_5 = endtime_5, _endtime_6 = endtime_6, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory ParticipantsDev({String? id, int? physically_1, int? physically_2, int? physically_3, int? physically_4, int? physically_5, int? physically_6, int? emotionally_1, int? emotionally_2, int? emotionally_3, int? emotionally_4, int? emotionally_5, int? emotionally_6, int? intensity_1, int? intensity_2, int? intensity_3, int? intensity_4, int? intensity_5, int? intensity_6, int? lonely_1, int? lonely_2, int? lonely_3, int? lonely_4, int? lonely_5, int? lonely_6, int? left_out_1, int? left_out_2, int? left_out_3, int? left_out_4, int? left_out_5, int? left_out_6, int? social_interaction_1, int? social_interaction_2, int? social_interaction_3, int? social_interaction_4, int? social_interaction_5, int? social_interaction_6, int? understood_1, int? understood_2, int? understood_3, int? understood_4, int? understood_5, int? understood_6, int? stressed_1, int? stressed_2, int? stressed_3, int? stressed_4, int? stressed_5, int? stressed_6, String? where_you_are_1, String? where_you_are_2, String? where_you_are_3, String? where_you_are_4, String? where_you_are_5, String? where_you_are_6, String? people_around_you_1, String? people_around_you_2, String? people_around_you_3, String? people_around_you_4, String? people_around_you_5, String? people_around_you_6, String? starttime_1, String? starttime_2, String? starttime_3, String? starttime_4, String? starttime_5, String? starttime_6, String? endtime_1, String? endtime_2, String? endtime_3, String? endtime_4, String? endtime_5, String? endtime_6}) {
    return ParticipantsDev._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      physically_1: physically_1,
      physically_2: physically_2,
      physically_3: physically_3,
      physically_4: physically_4,
      physically_5: physically_5,
      physically_6: physically_6,
      emotionally_1: emotionally_1,
      emotionally_2: emotionally_2,
      emotionally_3: emotionally_3,
      emotionally_4: emotionally_4,
      emotionally_5: emotionally_5,
      emotionally_6: emotionally_6,
      intensity_1: intensity_1,
      intensity_2: intensity_2,
      intensity_3: intensity_3,
      intensity_4: intensity_4,
      intensity_5: intensity_5,
      intensity_6: intensity_6,
      lonely_1: lonely_1,
      lonely_2: lonely_2,
      lonely_3: lonely_3,
      lonely_4: lonely_4,
      lonely_5: lonely_5,
      lonely_6: lonely_6,
      left_out_1: left_out_1,
      left_out_2: left_out_2,
      left_out_3: left_out_3,
      left_out_4: left_out_4,
      left_out_5: left_out_5,
      left_out_6: left_out_6,
      social_interaction_1: social_interaction_1,
      social_interaction_2: social_interaction_2,
      social_interaction_3: social_interaction_3,
      social_interaction_4: social_interaction_4,
      social_interaction_5: social_interaction_5,
      social_interaction_6: social_interaction_6,
      understood_1: understood_1,
      understood_2: understood_2,
      understood_3: understood_3,
      understood_4: understood_4,
      understood_5: understood_5,
      understood_6: understood_6,
      stressed_1: stressed_1,
      stressed_2: stressed_2,
      stressed_3: stressed_3,
      stressed_4: stressed_4,
      stressed_5: stressed_5,
      stressed_6: stressed_6,
      where_you_are_1: where_you_are_1,
      where_you_are_2: where_you_are_2,
      where_you_are_3: where_you_are_3,
      where_you_are_4: where_you_are_4,
      where_you_are_5: where_you_are_5,
      where_you_are_6: where_you_are_6,
      people_around_you_1: people_around_you_1,
      people_around_you_2: people_around_you_2,
      people_around_you_3: people_around_you_3,
      people_around_you_4: people_around_you_4,
      people_around_you_5: people_around_you_5,
      people_around_you_6: people_around_you_6,
      starttime_1: starttime_1,
      starttime_2: starttime_2,
      starttime_3: starttime_3,
      starttime_4: starttime_4,
      starttime_5: starttime_5,
      starttime_6: starttime_6,
      endtime_1: endtime_1,
      endtime_2: endtime_2,
      endtime_3: endtime_3,
      endtime_4: endtime_4,
      endtime_5: endtime_5,
      endtime_6: endtime_6);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ParticipantsDev &&
      id == other.id &&
      _physically_1 == other._physically_1 &&
      _physically_2 == other._physically_2 &&
      _physically_3 == other._physically_3 &&
      _physically_4 == other._physically_4 &&
      _physically_5 == other._physically_5 &&
      _physically_6 == other._physically_6 &&
      _emotionally_1 == other._emotionally_1 &&
      _emotionally_2 == other._emotionally_2 &&
      _emotionally_3 == other._emotionally_3 &&
      _emotionally_4 == other._emotionally_4 &&
      _emotionally_5 == other._emotionally_5 &&
      _emotionally_6 == other._emotionally_6 &&
      _intensity_1 == other._intensity_1 &&
      _intensity_2 == other._intensity_2 &&
      _intensity_3 == other._intensity_3 &&
      _intensity_4 == other._intensity_4 &&
      _intensity_5 == other._intensity_5 &&
      _intensity_6 == other._intensity_6 &&
      _lonely_1 == other._lonely_1 &&
      _lonely_2 == other._lonely_2 &&
      _lonely_3 == other._lonely_3 &&
      _lonely_4 == other._lonely_4 &&
      _lonely_5 == other._lonely_5 &&
      _lonely_6 == other._lonely_6 &&
      _left_out_1 == other._left_out_1 &&
      _left_out_2 == other._left_out_2 &&
      _left_out_3 == other._left_out_3 &&
      _left_out_4 == other._left_out_4 &&
      _left_out_5 == other._left_out_5 &&
      _left_out_6 == other._left_out_6 &&
      _social_interaction_1 == other._social_interaction_1 &&
      _social_interaction_2 == other._social_interaction_2 &&
      _social_interaction_3 == other._social_interaction_3 &&
      _social_interaction_4 == other._social_interaction_4 &&
      _social_interaction_5 == other._social_interaction_5 &&
      _social_interaction_6 == other._social_interaction_6 &&
      _understood_1 == other._understood_1 &&
      _understood_2 == other._understood_2 &&
      _understood_3 == other._understood_3 &&
      _understood_4 == other._understood_4 &&
      _understood_5 == other._understood_5 &&
      _understood_6 == other._understood_6 &&
      _stressed_1 == other._stressed_1 &&
      _stressed_2 == other._stressed_2 &&
      _stressed_3 == other._stressed_3 &&
      _stressed_4 == other._stressed_4 &&
      _stressed_5 == other._stressed_5 &&
      _stressed_6 == other._stressed_6 &&
      _where_you_are_1 == other._where_you_are_1 &&
      _where_you_are_2 == other._where_you_are_2 &&
      _where_you_are_3 == other._where_you_are_3 &&
      _where_you_are_4 == other._where_you_are_4 &&
      _where_you_are_5 == other._where_you_are_5 &&
      _where_you_are_6 == other._where_you_are_6 &&
      _people_around_you_1 == other._people_around_you_1 &&
      _people_around_you_2 == other._people_around_you_2 &&
      _people_around_you_3 == other._people_around_you_3 &&
      _people_around_you_4 == other._people_around_you_4 &&
      _people_around_you_5 == other._people_around_you_5 &&
      _people_around_you_6 == other._people_around_you_6 &&
      _starttime_1 == other._starttime_1 &&
      _starttime_2 == other._starttime_2 &&
      _starttime_3 == other._starttime_3 &&
      _starttime_4 == other._starttime_4 &&
      _starttime_5 == other._starttime_5 &&
      _starttime_6 == other._starttime_6 &&
      _endtime_1 == other._endtime_1 &&
      _endtime_2 == other._endtime_2 &&
      _endtime_3 == other._endtime_3 &&
      _endtime_4 == other._endtime_4 &&
      _endtime_5 == other._endtime_5 &&
      _endtime_6 == other._endtime_6;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ParticipantsDev {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("physically_1=" + (_physically_1 != null ? _physically_1!.toString() : "null") + ", ");
    buffer.write("physically_2=" + (_physically_2 != null ? _physically_2!.toString() : "null") + ", ");
    buffer.write("physically_3=" + (_physically_3 != null ? _physically_3!.toString() : "null") + ", ");
    buffer.write("physically_4=" + (_physically_4 != null ? _physically_4!.toString() : "null") + ", ");
    buffer.write("physically_5=" + (_physically_5 != null ? _physically_5!.toString() : "null") + ", ");
    buffer.write("physically_6=" + (_physically_6 != null ? _physically_6!.toString() : "null") + ", ");
    buffer.write("emotionally_1=" + (_emotionally_1 != null ? _emotionally_1!.toString() : "null") + ", ");
    buffer.write("emotionally_2=" + (_emotionally_2 != null ? _emotionally_2!.toString() : "null") + ", ");
    buffer.write("emotionally_3=" + (_emotionally_3 != null ? _emotionally_3!.toString() : "null") + ", ");
    buffer.write("emotionally_4=" + (_emotionally_4 != null ? _emotionally_4!.toString() : "null") + ", ");
    buffer.write("emotionally_5=" + (_emotionally_5 != null ? _emotionally_5!.toString() : "null") + ", ");
    buffer.write("emotionally_6=" + (_emotionally_6 != null ? _emotionally_6!.toString() : "null") + ", ");
    buffer.write("intensity_1=" + (_intensity_1 != null ? _intensity_1!.toString() : "null") + ", ");
    buffer.write("intensity_2=" + (_intensity_2 != null ? _intensity_2!.toString() : "null") + ", ");
    buffer.write("intensity_3=" + (_intensity_3 != null ? _intensity_3!.toString() : "null") + ", ");
    buffer.write("intensity_4=" + (_intensity_4 != null ? _intensity_4!.toString() : "null") + ", ");
    buffer.write("intensity_5=" + (_intensity_5 != null ? _intensity_5!.toString() : "null") + ", ");
    buffer.write("intensity_6=" + (_intensity_6 != null ? _intensity_6!.toString() : "null") + ", ");
    buffer.write("lonely_1=" + (_lonely_1 != null ? _lonely_1!.toString() : "null") + ", ");
    buffer.write("lonely_2=" + (_lonely_2 != null ? _lonely_2!.toString() : "null") + ", ");
    buffer.write("lonely_3=" + (_lonely_3 != null ? _lonely_3!.toString() : "null") + ", ");
    buffer.write("lonely_4=" + (_lonely_4 != null ? _lonely_4!.toString() : "null") + ", ");
    buffer.write("lonely_5=" + (_lonely_5 != null ? _lonely_5!.toString() : "null") + ", ");
    buffer.write("lonely_6=" + (_lonely_6 != null ? _lonely_6!.toString() : "null") + ", ");
    buffer.write("left_out_1=" + (_left_out_1 != null ? _left_out_1!.toString() : "null") + ", ");
    buffer.write("left_out_2=" + (_left_out_2 != null ? _left_out_2!.toString() : "null") + ", ");
    buffer.write("left_out_3=" + (_left_out_3 != null ? _left_out_3!.toString() : "null") + ", ");
    buffer.write("left_out_4=" + (_left_out_4 != null ? _left_out_4!.toString() : "null") + ", ");
    buffer.write("left_out_5=" + (_left_out_5 != null ? _left_out_5!.toString() : "null") + ", ");
    buffer.write("left_out_6=" + (_left_out_6 != null ? _left_out_6!.toString() : "null") + ", ");
    buffer.write("social_interaction_1=" + (_social_interaction_1 != null ? _social_interaction_1!.toString() : "null") + ", ");
    buffer.write("social_interaction_2=" + (_social_interaction_2 != null ? _social_interaction_2!.toString() : "null") + ", ");
    buffer.write("social_interaction_3=" + (_social_interaction_3 != null ? _social_interaction_3!.toString() : "null") + ", ");
    buffer.write("social_interaction_4=" + (_social_interaction_4 != null ? _social_interaction_4!.toString() : "null") + ", ");
    buffer.write("social_interaction_5=" + (_social_interaction_5 != null ? _social_interaction_5!.toString() : "null") + ", ");
    buffer.write("social_interaction_6=" + (_social_interaction_6 != null ? _social_interaction_6!.toString() : "null") + ", ");
    buffer.write("understood_1=" + (_understood_1 != null ? _understood_1!.toString() : "null") + ", ");
    buffer.write("understood_2=" + (_understood_2 != null ? _understood_2!.toString() : "null") + ", ");
    buffer.write("understood_3=" + (_understood_3 != null ? _understood_3!.toString() : "null") + ", ");
    buffer.write("understood_4=" + (_understood_4 != null ? _understood_4!.toString() : "null") + ", ");
    buffer.write("understood_5=" + (_understood_5 != null ? _understood_5!.toString() : "null") + ", ");
    buffer.write("understood_6=" + (_understood_6 != null ? _understood_6!.toString() : "null") + ", ");
    buffer.write("stressed_1=" + (_stressed_1 != null ? _stressed_1!.toString() : "null") + ", ");
    buffer.write("stressed_2=" + (_stressed_2 != null ? _stressed_2!.toString() : "null") + ", ");
    buffer.write("stressed_3=" + (_stressed_3 != null ? _stressed_3!.toString() : "null") + ", ");
    buffer.write("stressed_4=" + (_stressed_4 != null ? _stressed_4!.toString() : "null") + ", ");
    buffer.write("stressed_5=" + (_stressed_5 != null ? _stressed_5!.toString() : "null") + ", ");
    buffer.write("stressed_6=" + (_stressed_6 != null ? _stressed_6!.toString() : "null") + ", ");
    buffer.write("where_you_are_1=" + "$_where_you_are_1" + ", ");
    buffer.write("where_you_are_2=" + "$_where_you_are_2" + ", ");
    buffer.write("where_you_are_3=" + "$_where_you_are_3" + ", ");
    buffer.write("where_you_are_4=" + "$_where_you_are_4" + ", ");
    buffer.write("where_you_are_5=" + "$_where_you_are_5" + ", ");
    buffer.write("where_you_are_6=" + "$_where_you_are_6" + ", ");
    buffer.write("people_around_you_1=" + "$_people_around_you_1" + ", ");
    buffer.write("people_around_you_2=" + "$_people_around_you_2" + ", ");
    buffer.write("people_around_you_3=" + "$_people_around_you_3" + ", ");
    buffer.write("people_around_you_4=" + "$_people_around_you_4" + ", ");
    buffer.write("people_around_you_5=" + "$_people_around_you_5" + ", ");
    buffer.write("people_around_you_6=" + "$_people_around_you_6" + ", ");
    buffer.write("starttime_1=" + "$_starttime_1" + ", ");
    buffer.write("starttime_2=" + "$_starttime_2" + ", ");
    buffer.write("starttime_3=" + "$_starttime_3" + ", ");
    buffer.write("starttime_4=" + "$_starttime_4" + ", ");
    buffer.write("starttime_5=" + "$_starttime_5" + ", ");
    buffer.write("starttime_6=" + "$_starttime_6" + ", ");
    buffer.write("endtime_1=" + "$_endtime_1" + ", ");
    buffer.write("endtime_2=" + "$_endtime_2" + ", ");
    buffer.write("endtime_3=" + "$_endtime_3" + ", ");
    buffer.write("endtime_4=" + "$_endtime_4" + ", ");
    buffer.write("endtime_5=" + "$_endtime_5" + ", ");
    buffer.write("endtime_6=" + "$_endtime_6" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ParticipantsDev copyWith({int? physically_1, int? physically_2, int? physically_3, int? physically_4, int? physically_5, int? physically_6, int? emotionally_1, int? emotionally_2, int? emotionally_3, int? emotionally_4, int? emotionally_5, int? emotionally_6, int? intensity_1, int? intensity_2, int? intensity_3, int? intensity_4, int? intensity_5, int? intensity_6, int? lonely_1, int? lonely_2, int? lonely_3, int? lonely_4, int? lonely_5, int? lonely_6, int? left_out_1, int? left_out_2, int? left_out_3, int? left_out_4, int? left_out_5, int? left_out_6, int? social_interaction_1, int? social_interaction_2, int? social_interaction_3, int? social_interaction_4, int? social_interaction_5, int? social_interaction_6, int? understood_1, int? understood_2, int? understood_3, int? understood_4, int? understood_5, int? understood_6, int? stressed_1, int? stressed_2, int? stressed_3, int? stressed_4, int? stressed_5, int? stressed_6, String? where_you_are_1, String? where_you_are_2, String? where_you_are_3, String? where_you_are_4, String? where_you_are_5, String? where_you_are_6, String? people_around_you_1, String? people_around_you_2, String? people_around_you_3, String? people_around_you_4, String? people_around_you_5, String? people_around_you_6, String? starttime_1, String? starttime_2, String? starttime_3, String? starttime_4, String? starttime_5, String? starttime_6, String? endtime_1, String? endtime_2, String? endtime_3, String? endtime_4, String? endtime_5, String? endtime_6}) {
    return ParticipantsDev._internal(
      id: id,
      physically_1: physically_1 ?? this.physically_1,
      physically_2: physically_2 ?? this.physically_2,
      physically_3: physically_3 ?? this.physically_3,
      physically_4: physically_4 ?? this.physically_4,
      physically_5: physically_5 ?? this.physically_5,
      physically_6: physically_6 ?? this.physically_6,
      emotionally_1: emotionally_1 ?? this.emotionally_1,
      emotionally_2: emotionally_2 ?? this.emotionally_2,
      emotionally_3: emotionally_3 ?? this.emotionally_3,
      emotionally_4: emotionally_4 ?? this.emotionally_4,
      emotionally_5: emotionally_5 ?? this.emotionally_5,
      emotionally_6: emotionally_6 ?? this.emotionally_6,
      intensity_1: intensity_1 ?? this.intensity_1,
      intensity_2: intensity_2 ?? this.intensity_2,
      intensity_3: intensity_3 ?? this.intensity_3,
      intensity_4: intensity_4 ?? this.intensity_4,
      intensity_5: intensity_5 ?? this.intensity_5,
      intensity_6: intensity_6 ?? this.intensity_6,
      lonely_1: lonely_1 ?? this.lonely_1,
      lonely_2: lonely_2 ?? this.lonely_2,
      lonely_3: lonely_3 ?? this.lonely_3,
      lonely_4: lonely_4 ?? this.lonely_4,
      lonely_5: lonely_5 ?? this.lonely_5,
      lonely_6: lonely_6 ?? this.lonely_6,
      left_out_1: left_out_1 ?? this.left_out_1,
      left_out_2: left_out_2 ?? this.left_out_2,
      left_out_3: left_out_3 ?? this.left_out_3,
      left_out_4: left_out_4 ?? this.left_out_4,
      left_out_5: left_out_5 ?? this.left_out_5,
      left_out_6: left_out_6 ?? this.left_out_6,
      social_interaction_1: social_interaction_1 ?? this.social_interaction_1,
      social_interaction_2: social_interaction_2 ?? this.social_interaction_2,
      social_interaction_3: social_interaction_3 ?? this.social_interaction_3,
      social_interaction_4: social_interaction_4 ?? this.social_interaction_4,
      social_interaction_5: social_interaction_5 ?? this.social_interaction_5,
      social_interaction_6: social_interaction_6 ?? this.social_interaction_6,
      understood_1: understood_1 ?? this.understood_1,
      understood_2: understood_2 ?? this.understood_2,
      understood_3: understood_3 ?? this.understood_3,
      understood_4: understood_4 ?? this.understood_4,
      understood_5: understood_5 ?? this.understood_5,
      understood_6: understood_6 ?? this.understood_6,
      stressed_1: stressed_1 ?? this.stressed_1,
      stressed_2: stressed_2 ?? this.stressed_2,
      stressed_3: stressed_3 ?? this.stressed_3,
      stressed_4: stressed_4 ?? this.stressed_4,
      stressed_5: stressed_5 ?? this.stressed_5,
      stressed_6: stressed_6 ?? this.stressed_6,
      where_you_are_1: where_you_are_1 ?? this.where_you_are_1,
      where_you_are_2: where_you_are_2 ?? this.where_you_are_2,
      where_you_are_3: where_you_are_3 ?? this.where_you_are_3,
      where_you_are_4: where_you_are_4 ?? this.where_you_are_4,
      where_you_are_5: where_you_are_5 ?? this.where_you_are_5,
      where_you_are_6: where_you_are_6 ?? this.where_you_are_6,
      people_around_you_1: people_around_you_1 ?? this.people_around_you_1,
      people_around_you_2: people_around_you_2 ?? this.people_around_you_2,
      people_around_you_3: people_around_you_3 ?? this.people_around_you_3,
      people_around_you_4: people_around_you_4 ?? this.people_around_you_4,
      people_around_you_5: people_around_you_5 ?? this.people_around_you_5,
      people_around_you_6: people_around_you_6 ?? this.people_around_you_6,
      starttime_1: starttime_1 ?? this.starttime_1,
      starttime_2: starttime_2 ?? this.starttime_2,
      starttime_3: starttime_3 ?? this.starttime_3,
      starttime_4: starttime_4 ?? this.starttime_4,
      starttime_5: starttime_5 ?? this.starttime_5,
      starttime_6: starttime_6 ?? this.starttime_6,
      endtime_1: endtime_1 ?? this.endtime_1,
      endtime_2: endtime_2 ?? this.endtime_2,
      endtime_3: endtime_3 ?? this.endtime_3,
      endtime_4: endtime_4 ?? this.endtime_4,
      endtime_5: endtime_5 ?? this.endtime_5,
      endtime_6: endtime_6 ?? this.endtime_6);
  }
  
  ParticipantsDev copyWithModelFieldValues({
    ModelFieldValue<int?>? physically_1,
    ModelFieldValue<int?>? physically_2,
    ModelFieldValue<int?>? physically_3,
    ModelFieldValue<int?>? physically_4,
    ModelFieldValue<int?>? physically_5,
    ModelFieldValue<int?>? physically_6,
    ModelFieldValue<int?>? emotionally_1,
    ModelFieldValue<int?>? emotionally_2,
    ModelFieldValue<int?>? emotionally_3,
    ModelFieldValue<int?>? emotionally_4,
    ModelFieldValue<int?>? emotionally_5,
    ModelFieldValue<int?>? emotionally_6,
    ModelFieldValue<int?>? intensity_1,
    ModelFieldValue<int?>? intensity_2,
    ModelFieldValue<int?>? intensity_3,
    ModelFieldValue<int?>? intensity_4,
    ModelFieldValue<int?>? intensity_5,
    ModelFieldValue<int?>? intensity_6,
    ModelFieldValue<int?>? lonely_1,
    ModelFieldValue<int?>? lonely_2,
    ModelFieldValue<int?>? lonely_3,
    ModelFieldValue<int?>? lonely_4,
    ModelFieldValue<int?>? lonely_5,
    ModelFieldValue<int?>? lonely_6,
    ModelFieldValue<int?>? left_out_1,
    ModelFieldValue<int?>? left_out_2,
    ModelFieldValue<int?>? left_out_3,
    ModelFieldValue<int?>? left_out_4,
    ModelFieldValue<int?>? left_out_5,
    ModelFieldValue<int?>? left_out_6,
    ModelFieldValue<int?>? social_interaction_1,
    ModelFieldValue<int?>? social_interaction_2,
    ModelFieldValue<int?>? social_interaction_3,
    ModelFieldValue<int?>? social_interaction_4,
    ModelFieldValue<int?>? social_interaction_5,
    ModelFieldValue<int?>? social_interaction_6,
    ModelFieldValue<int?>? understood_1,
    ModelFieldValue<int?>? understood_2,
    ModelFieldValue<int?>? understood_3,
    ModelFieldValue<int?>? understood_4,
    ModelFieldValue<int?>? understood_5,
    ModelFieldValue<int?>? understood_6,
    ModelFieldValue<int?>? stressed_1,
    ModelFieldValue<int?>? stressed_2,
    ModelFieldValue<int?>? stressed_3,
    ModelFieldValue<int?>? stressed_4,
    ModelFieldValue<int?>? stressed_5,
    ModelFieldValue<int?>? stressed_6,
    ModelFieldValue<String?>? where_you_are_1,
    ModelFieldValue<String?>? where_you_are_2,
    ModelFieldValue<String?>? where_you_are_3,
    ModelFieldValue<String?>? where_you_are_4,
    ModelFieldValue<String?>? where_you_are_5,
    ModelFieldValue<String?>? where_you_are_6,
    ModelFieldValue<String?>? people_around_you_1,
    ModelFieldValue<String?>? people_around_you_2,
    ModelFieldValue<String?>? people_around_you_3,
    ModelFieldValue<String?>? people_around_you_4,
    ModelFieldValue<String?>? people_around_you_5,
    ModelFieldValue<String?>? people_around_you_6,
    ModelFieldValue<String?>? starttime_1,
    ModelFieldValue<String?>? starttime_2,
    ModelFieldValue<String?>? starttime_3,
    ModelFieldValue<String?>? starttime_4,
    ModelFieldValue<String?>? starttime_5,
    ModelFieldValue<String?>? starttime_6,
    ModelFieldValue<String?>? endtime_1,
    ModelFieldValue<String?>? endtime_2,
    ModelFieldValue<String?>? endtime_3,
    ModelFieldValue<String?>? endtime_4,
    ModelFieldValue<String?>? endtime_5,
    ModelFieldValue<String?>? endtime_6
  }) {
    return ParticipantsDev._internal(
      id: id,
      physically_1: physically_1 == null ? this.physically_1 : physically_1.value,
      physically_2: physically_2 == null ? this.physically_2 : physically_2.value,
      physically_3: physically_3 == null ? this.physically_3 : physically_3.value,
      physically_4: physically_4 == null ? this.physically_4 : physically_4.value,
      physically_5: physically_5 == null ? this.physically_5 : physically_5.value,
      physically_6: physically_6 == null ? this.physically_6 : physically_6.value,
      emotionally_1: emotionally_1 == null ? this.emotionally_1 : emotionally_1.value,
      emotionally_2: emotionally_2 == null ? this.emotionally_2 : emotionally_2.value,
      emotionally_3: emotionally_3 == null ? this.emotionally_3 : emotionally_3.value,
      emotionally_4: emotionally_4 == null ? this.emotionally_4 : emotionally_4.value,
      emotionally_5: emotionally_5 == null ? this.emotionally_5 : emotionally_5.value,
      emotionally_6: emotionally_6 == null ? this.emotionally_6 : emotionally_6.value,
      intensity_1: intensity_1 == null ? this.intensity_1 : intensity_1.value,
      intensity_2: intensity_2 == null ? this.intensity_2 : intensity_2.value,
      intensity_3: intensity_3 == null ? this.intensity_3 : intensity_3.value,
      intensity_4: intensity_4 == null ? this.intensity_4 : intensity_4.value,
      intensity_5: intensity_5 == null ? this.intensity_5 : intensity_5.value,
      intensity_6: intensity_6 == null ? this.intensity_6 : intensity_6.value,
      lonely_1: lonely_1 == null ? this.lonely_1 : lonely_1.value,
      lonely_2: lonely_2 == null ? this.lonely_2 : lonely_2.value,
      lonely_3: lonely_3 == null ? this.lonely_3 : lonely_3.value,
      lonely_4: lonely_4 == null ? this.lonely_4 : lonely_4.value,
      lonely_5: lonely_5 == null ? this.lonely_5 : lonely_5.value,
      lonely_6: lonely_6 == null ? this.lonely_6 : lonely_6.value,
      left_out_1: left_out_1 == null ? this.left_out_1 : left_out_1.value,
      left_out_2: left_out_2 == null ? this.left_out_2 : left_out_2.value,
      left_out_3: left_out_3 == null ? this.left_out_3 : left_out_3.value,
      left_out_4: left_out_4 == null ? this.left_out_4 : left_out_4.value,
      left_out_5: left_out_5 == null ? this.left_out_5 : left_out_5.value,
      left_out_6: left_out_6 == null ? this.left_out_6 : left_out_6.value,
      social_interaction_1: social_interaction_1 == null ? this.social_interaction_1 : social_interaction_1.value,
      social_interaction_2: social_interaction_2 == null ? this.social_interaction_2 : social_interaction_2.value,
      social_interaction_3: social_interaction_3 == null ? this.social_interaction_3 : social_interaction_3.value,
      social_interaction_4: social_interaction_4 == null ? this.social_interaction_4 : social_interaction_4.value,
      social_interaction_5: social_interaction_5 == null ? this.social_interaction_5 : social_interaction_5.value,
      social_interaction_6: social_interaction_6 == null ? this.social_interaction_6 : social_interaction_6.value,
      understood_1: understood_1 == null ? this.understood_1 : understood_1.value,
      understood_2: understood_2 == null ? this.understood_2 : understood_2.value,
      understood_3: understood_3 == null ? this.understood_3 : understood_3.value,
      understood_4: understood_4 == null ? this.understood_4 : understood_4.value,
      understood_5: understood_5 == null ? this.understood_5 : understood_5.value,
      understood_6: understood_6 == null ? this.understood_6 : understood_6.value,
      stressed_1: stressed_1 == null ? this.stressed_1 : stressed_1.value,
      stressed_2: stressed_2 == null ? this.stressed_2 : stressed_2.value,
      stressed_3: stressed_3 == null ? this.stressed_3 : stressed_3.value,
      stressed_4: stressed_4 == null ? this.stressed_4 : stressed_4.value,
      stressed_5: stressed_5 == null ? this.stressed_5 : stressed_5.value,
      stressed_6: stressed_6 == null ? this.stressed_6 : stressed_6.value,
      where_you_are_1: where_you_are_1 == null ? this.where_you_are_1 : where_you_are_1.value,
      where_you_are_2: where_you_are_2 == null ? this.where_you_are_2 : where_you_are_2.value,
      where_you_are_3: where_you_are_3 == null ? this.where_you_are_3 : where_you_are_3.value,
      where_you_are_4: where_you_are_4 == null ? this.where_you_are_4 : where_you_are_4.value,
      where_you_are_5: where_you_are_5 == null ? this.where_you_are_5 : where_you_are_5.value,
      where_you_are_6: where_you_are_6 == null ? this.where_you_are_6 : where_you_are_6.value,
      people_around_you_1: people_around_you_1 == null ? this.people_around_you_1 : people_around_you_1.value,
      people_around_you_2: people_around_you_2 == null ? this.people_around_you_2 : people_around_you_2.value,
      people_around_you_3: people_around_you_3 == null ? this.people_around_you_3 : people_around_you_3.value,
      people_around_you_4: people_around_you_4 == null ? this.people_around_you_4 : people_around_you_4.value,
      people_around_you_5: people_around_you_5 == null ? this.people_around_you_5 : people_around_you_5.value,
      people_around_you_6: people_around_you_6 == null ? this.people_around_you_6 : people_around_you_6.value,
      starttime_1: starttime_1 == null ? this.starttime_1 : starttime_1.value,
      starttime_2: starttime_2 == null ? this.starttime_2 : starttime_2.value,
      starttime_3: starttime_3 == null ? this.starttime_3 : starttime_3.value,
      starttime_4: starttime_4 == null ? this.starttime_4 : starttime_4.value,
      starttime_5: starttime_5 == null ? this.starttime_5 : starttime_5.value,
      starttime_6: starttime_6 == null ? this.starttime_6 : starttime_6.value,
      endtime_1: endtime_1 == null ? this.endtime_1 : endtime_1.value,
      endtime_2: endtime_2 == null ? this.endtime_2 : endtime_2.value,
      endtime_3: endtime_3 == null ? this.endtime_3 : endtime_3.value,
      endtime_4: endtime_4 == null ? this.endtime_4 : endtime_4.value,
      endtime_5: endtime_5 == null ? this.endtime_5 : endtime_5.value,
      endtime_6: endtime_6 == null ? this.endtime_6 : endtime_6.value
    );
  }
  
  ParticipantsDev.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _physically_1 = (json['physically_1'] as num?)?.toInt(),
      _physically_2 = (json['physically_2'] as num?)?.toInt(),
      _physically_3 = (json['physically_3'] as num?)?.toInt(),
      _physically_4 = (json['physically_4'] as num?)?.toInt(),
      _physically_5 = (json['physically_5'] as num?)?.toInt(),
      _physically_6 = (json['physically_6'] as num?)?.toInt(),
      _emotionally_1 = (json['emotionally_1'] as num?)?.toInt(),
      _emotionally_2 = (json['emotionally_2'] as num?)?.toInt(),
      _emotionally_3 = (json['emotionally_3'] as num?)?.toInt(),
      _emotionally_4 = (json['emotionally_4'] as num?)?.toInt(),
      _emotionally_5 = (json['emotionally_5'] as num?)?.toInt(),
      _emotionally_6 = (json['emotionally_6'] as num?)?.toInt(),
      _intensity_1 = (json['intensity_1'] as num?)?.toInt(),
      _intensity_2 = (json['intensity_2'] as num?)?.toInt(),
      _intensity_3 = (json['intensity_3'] as num?)?.toInt(),
      _intensity_4 = (json['intensity_4'] as num?)?.toInt(),
      _intensity_5 = (json['intensity_5'] as num?)?.toInt(),
      _intensity_6 = (json['intensity_6'] as num?)?.toInt(),
      _lonely_1 = (json['lonely_1'] as num?)?.toInt(),
      _lonely_2 = (json['lonely_2'] as num?)?.toInt(),
      _lonely_3 = (json['lonely_3'] as num?)?.toInt(),
      _lonely_4 = (json['lonely_4'] as num?)?.toInt(),
      _lonely_5 = (json['lonely_5'] as num?)?.toInt(),
      _lonely_6 = (json['lonely_6'] as num?)?.toInt(),
      _left_out_1 = (json['left_out_1'] as num?)?.toInt(),
      _left_out_2 = (json['left_out_2'] as num?)?.toInt(),
      _left_out_3 = (json['left_out_3'] as num?)?.toInt(),
      _left_out_4 = (json['left_out_4'] as num?)?.toInt(),
      _left_out_5 = (json['left_out_5'] as num?)?.toInt(),
      _left_out_6 = (json['left_out_6'] as num?)?.toInt(),
      _social_interaction_1 = (json['social_interaction_1'] as num?)?.toInt(),
      _social_interaction_2 = (json['social_interaction_2'] as num?)?.toInt(),
      _social_interaction_3 = (json['social_interaction_3'] as num?)?.toInt(),
      _social_interaction_4 = (json['social_interaction_4'] as num?)?.toInt(),
      _social_interaction_5 = (json['social_interaction_5'] as num?)?.toInt(),
      _social_interaction_6 = (json['social_interaction_6'] as num?)?.toInt(),
      _understood_1 = (json['understood_1'] as num?)?.toInt(),
      _understood_2 = (json['understood_2'] as num?)?.toInt(),
      _understood_3 = (json['understood_3'] as num?)?.toInt(),
      _understood_4 = (json['understood_4'] as num?)?.toInt(),
      _understood_5 = (json['understood_5'] as num?)?.toInt(),
      _understood_6 = (json['understood_6'] as num?)?.toInt(),
      _stressed_1 = (json['stressed_1'] as num?)?.toInt(),
      _stressed_2 = (json['stressed_2'] as num?)?.toInt(),
      _stressed_3 = (json['stressed_3'] as num?)?.toInt(),
      _stressed_4 = (json['stressed_4'] as num?)?.toInt(),
      _stressed_5 = (json['stressed_5'] as num?)?.toInt(),
      _stressed_6 = (json['stressed_6'] as num?)?.toInt(),
      _where_you_are_1 = json['where_you_are_1'],
      _where_you_are_2 = json['where_you_are_2'],
      _where_you_are_3 = json['where_you_are_3'],
      _where_you_are_4 = json['where_you_are_4'],
      _where_you_are_5 = json['where_you_are_5'],
      _where_you_are_6 = json['where_you_are_6'],
      _people_around_you_1 = json['people_around_you_1'],
      _people_around_you_2 = json['people_around_you_2'],
      _people_around_you_3 = json['people_around_you_3'],
      _people_around_you_4 = json['people_around_you_4'],
      _people_around_you_5 = json['people_around_you_5'],
      _people_around_you_6 = json['people_around_you_6'],
      _starttime_1 = json['starttime_1'],
      _starttime_2 = json['starttime_2'],
      _starttime_3 = json['starttime_3'],
      _starttime_4 = json['starttime_4'],
      _starttime_5 = json['starttime_5'],
      _starttime_6 = json['starttime_6'],
      _endtime_1 = json['endtime_1'],
      _endtime_2 = json['endtime_2'],
      _endtime_3 = json['endtime_3'],
      _endtime_4 = json['endtime_4'],
      _endtime_5 = json['endtime_5'],
      _endtime_6 = json['endtime_6'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'physically_1': _physically_1, 'physically_2': _physically_2, 'physically_3': _physically_3, 'physically_4': _physically_4, 'physically_5': _physically_5, 'physically_6': _physically_6, 'emotionally_1': _emotionally_1, 'emotionally_2': _emotionally_2, 'emotionally_3': _emotionally_3, 'emotionally_4': _emotionally_4, 'emotionally_5': _emotionally_5, 'emotionally_6': _emotionally_6, 'intensity_1': _intensity_1, 'intensity_2': _intensity_2, 'intensity_3': _intensity_3, 'intensity_4': _intensity_4, 'intensity_5': _intensity_5, 'intensity_6': _intensity_6, 'lonely_1': _lonely_1, 'lonely_2': _lonely_2, 'lonely_3': _lonely_3, 'lonely_4': _lonely_4, 'lonely_5': _lonely_5, 'lonely_6': _lonely_6, 'left_out_1': _left_out_1, 'left_out_2': _left_out_2, 'left_out_3': _left_out_3, 'left_out_4': _left_out_4, 'left_out_5': _left_out_5, 'left_out_6': _left_out_6, 'social_interaction_1': _social_interaction_1, 'social_interaction_2': _social_interaction_2, 'social_interaction_3': _social_interaction_3, 'social_interaction_4': _social_interaction_4, 'social_interaction_5': _social_interaction_5, 'social_interaction_6': _social_interaction_6, 'understood_1': _understood_1, 'understood_2': _understood_2, 'understood_3': _understood_3, 'understood_4': _understood_4, 'understood_5': _understood_5, 'understood_6': _understood_6, 'stressed_1': _stressed_1, 'stressed_2': _stressed_2, 'stressed_3': _stressed_3, 'stressed_4': _stressed_4, 'stressed_5': _stressed_5, 'stressed_6': _stressed_6, 'where_you_are_1': _where_you_are_1, 'where_you_are_2': _where_you_are_2, 'where_you_are_3': _where_you_are_3, 'where_you_are_4': _where_you_are_4, 'where_you_are_5': _where_you_are_5, 'where_you_are_6': _where_you_are_6, 'people_around_you_1': _people_around_you_1, 'people_around_you_2': _people_around_you_2, 'people_around_you_3': _people_around_you_3, 'people_around_you_4': _people_around_you_4, 'people_around_you_5': _people_around_you_5, 'people_around_you_6': _people_around_you_6, 'starttime_1': _starttime_1, 'starttime_2': _starttime_2, 'starttime_3': _starttime_3, 'starttime_4': _starttime_4, 'starttime_5': _starttime_5, 'starttime_6': _starttime_6, 'endtime_1': _endtime_1, 'endtime_2': _endtime_2, 'endtime_3': _endtime_3, 'endtime_4': _endtime_4, 'endtime_5': _endtime_5, 'endtime_6': _endtime_6, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'physically_1': _physically_1,
    'physically_2': _physically_2,
    'physically_3': _physically_3,
    'physically_4': _physically_4,
    'physically_5': _physically_5,
    'physically_6': _physically_6,
    'emotionally_1': _emotionally_1,
    'emotionally_2': _emotionally_2,
    'emotionally_3': _emotionally_3,
    'emotionally_4': _emotionally_4,
    'emotionally_5': _emotionally_5,
    'emotionally_6': _emotionally_6,
    'intensity_1': _intensity_1,
    'intensity_2': _intensity_2,
    'intensity_3': _intensity_3,
    'intensity_4': _intensity_4,
    'intensity_5': _intensity_5,
    'intensity_6': _intensity_6,
    'lonely_1': _lonely_1,
    'lonely_2': _lonely_2,
    'lonely_3': _lonely_3,
    'lonely_4': _lonely_4,
    'lonely_5': _lonely_5,
    'lonely_6': _lonely_6,
    'left_out_1': _left_out_1,
    'left_out_2': _left_out_2,
    'left_out_3': _left_out_3,
    'left_out_4': _left_out_4,
    'left_out_5': _left_out_5,
    'left_out_6': _left_out_6,
    'social_interaction_1': _social_interaction_1,
    'social_interaction_2': _social_interaction_2,
    'social_interaction_3': _social_interaction_3,
    'social_interaction_4': _social_interaction_4,
    'social_interaction_5': _social_interaction_5,
    'social_interaction_6': _social_interaction_6,
    'understood_1': _understood_1,
    'understood_2': _understood_2,
    'understood_3': _understood_3,
    'understood_4': _understood_4,
    'understood_5': _understood_5,
    'understood_6': _understood_6,
    'stressed_1': _stressed_1,
    'stressed_2': _stressed_2,
    'stressed_3': _stressed_3,
    'stressed_4': _stressed_4,
    'stressed_5': _stressed_5,
    'stressed_6': _stressed_6,
    'where_you_are_1': _where_you_are_1,
    'where_you_are_2': _where_you_are_2,
    'where_you_are_3': _where_you_are_3,
    'where_you_are_4': _where_you_are_4,
    'where_you_are_5': _where_you_are_5,
    'where_you_are_6': _where_you_are_6,
    'people_around_you_1': _people_around_you_1,
    'people_around_you_2': _people_around_you_2,
    'people_around_you_3': _people_around_you_3,
    'people_around_you_4': _people_around_you_4,
    'people_around_you_5': _people_around_you_5,
    'people_around_you_6': _people_around_you_6,
    'starttime_1': _starttime_1,
    'starttime_2': _starttime_2,
    'starttime_3': _starttime_3,
    'starttime_4': _starttime_4,
    'starttime_5': _starttime_5,
    'starttime_6': _starttime_6,
    'endtime_1': _endtime_1,
    'endtime_2': _endtime_2,
    'endtime_3': _endtime_3,
    'endtime_4': _endtime_4,
    'endtime_5': _endtime_5,
    'endtime_6': _endtime_6,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ParticipantsDevModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ParticipantsDevModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final PHYSICALLY_1 = amplify_core.QueryField(fieldName: "physically_1");
  static final PHYSICALLY_2 = amplify_core.QueryField(fieldName: "physically_2");
  static final PHYSICALLY_3 = amplify_core.QueryField(fieldName: "physically_3");
  static final PHYSICALLY_4 = amplify_core.QueryField(fieldName: "physically_4");
  static final PHYSICALLY_5 = amplify_core.QueryField(fieldName: "physically_5");
  static final PHYSICALLY_6 = amplify_core.QueryField(fieldName: "physically_6");
  static final EMOTIONALLY_1 = amplify_core.QueryField(fieldName: "emotionally_1");
  static final EMOTIONALLY_2 = amplify_core.QueryField(fieldName: "emotionally_2");
  static final EMOTIONALLY_3 = amplify_core.QueryField(fieldName: "emotionally_3");
  static final EMOTIONALLY_4 = amplify_core.QueryField(fieldName: "emotionally_4");
  static final EMOTIONALLY_5 = amplify_core.QueryField(fieldName: "emotionally_5");
  static final EMOTIONALLY_6 = amplify_core.QueryField(fieldName: "emotionally_6");
  static final INTENSITY_1 = amplify_core.QueryField(fieldName: "intensity_1");
  static final INTENSITY_2 = amplify_core.QueryField(fieldName: "intensity_2");
  static final INTENSITY_3 = amplify_core.QueryField(fieldName: "intensity_3");
  static final INTENSITY_4 = amplify_core.QueryField(fieldName: "intensity_4");
  static final INTENSITY_5 = amplify_core.QueryField(fieldName: "intensity_5");
  static final INTENSITY_6 = amplify_core.QueryField(fieldName: "intensity_6");
  static final LONELY_1 = amplify_core.QueryField(fieldName: "lonely_1");
  static final LONELY_2 = amplify_core.QueryField(fieldName: "lonely_2");
  static final LONELY_3 = amplify_core.QueryField(fieldName: "lonely_3");
  static final LONELY_4 = amplify_core.QueryField(fieldName: "lonely_4");
  static final LONELY_5 = amplify_core.QueryField(fieldName: "lonely_5");
  static final LONELY_6 = amplify_core.QueryField(fieldName: "lonely_6");
  static final LEFT_OUT_1 = amplify_core.QueryField(fieldName: "left_out_1");
  static final LEFT_OUT_2 = amplify_core.QueryField(fieldName: "left_out_2");
  static final LEFT_OUT_3 = amplify_core.QueryField(fieldName: "left_out_3");
  static final LEFT_OUT_4 = amplify_core.QueryField(fieldName: "left_out_4");
  static final LEFT_OUT_5 = amplify_core.QueryField(fieldName: "left_out_5");
  static final LEFT_OUT_6 = amplify_core.QueryField(fieldName: "left_out_6");
  static final SOCIAL_INTERACTION_1 = amplify_core.QueryField(fieldName: "social_interaction_1");
  static final SOCIAL_INTERACTION_2 = amplify_core.QueryField(fieldName: "social_interaction_2");
  static final SOCIAL_INTERACTION_3 = amplify_core.QueryField(fieldName: "social_interaction_3");
  static final SOCIAL_INTERACTION_4 = amplify_core.QueryField(fieldName: "social_interaction_4");
  static final SOCIAL_INTERACTION_5 = amplify_core.QueryField(fieldName: "social_interaction_5");
  static final SOCIAL_INTERACTION_6 = amplify_core.QueryField(fieldName: "social_interaction_6");
  static final UNDERSTOOD_1 = amplify_core.QueryField(fieldName: "understood_1");
  static final UNDERSTOOD_2 = amplify_core.QueryField(fieldName: "understood_2");
  static final UNDERSTOOD_3 = amplify_core.QueryField(fieldName: "understood_3");
  static final UNDERSTOOD_4 = amplify_core.QueryField(fieldName: "understood_4");
  static final UNDERSTOOD_5 = amplify_core.QueryField(fieldName: "understood_5");
  static final UNDERSTOOD_6 = amplify_core.QueryField(fieldName: "understood_6");
  static final STRESSED_1 = amplify_core.QueryField(fieldName: "stressed_1");
  static final STRESSED_2 = amplify_core.QueryField(fieldName: "stressed_2");
  static final STRESSED_3 = amplify_core.QueryField(fieldName: "stressed_3");
  static final STRESSED_4 = amplify_core.QueryField(fieldName: "stressed_4");
  static final STRESSED_5 = amplify_core.QueryField(fieldName: "stressed_5");
  static final STRESSED_6 = amplify_core.QueryField(fieldName: "stressed_6");
  static final WHERE_YOU_ARE_1 = amplify_core.QueryField(fieldName: "where_you_are_1");
  static final WHERE_YOU_ARE_2 = amplify_core.QueryField(fieldName: "where_you_are_2");
  static final WHERE_YOU_ARE_3 = amplify_core.QueryField(fieldName: "where_you_are_3");
  static final WHERE_YOU_ARE_4 = amplify_core.QueryField(fieldName: "where_you_are_4");
  static final WHERE_YOU_ARE_5 = amplify_core.QueryField(fieldName: "where_you_are_5");
  static final WHERE_YOU_ARE_6 = amplify_core.QueryField(fieldName: "where_you_are_6");
  static final PEOPLE_AROUND_YOU_1 = amplify_core.QueryField(fieldName: "people_around_you_1");
  static final PEOPLE_AROUND_YOU_2 = amplify_core.QueryField(fieldName: "people_around_you_2");
  static final PEOPLE_AROUND_YOU_3 = amplify_core.QueryField(fieldName: "people_around_you_3");
  static final PEOPLE_AROUND_YOU_4 = amplify_core.QueryField(fieldName: "people_around_you_4");
  static final PEOPLE_AROUND_YOU_5 = amplify_core.QueryField(fieldName: "people_around_you_5");
  static final PEOPLE_AROUND_YOU_6 = amplify_core.QueryField(fieldName: "people_around_you_6");
  static final STARTTIME_1 = amplify_core.QueryField(fieldName: "starttime_1");
  static final STARTTIME_2 = amplify_core.QueryField(fieldName: "starttime_2");
  static final STARTTIME_3 = amplify_core.QueryField(fieldName: "starttime_3");
  static final STARTTIME_4 = amplify_core.QueryField(fieldName: "starttime_4");
  static final STARTTIME_5 = amplify_core.QueryField(fieldName: "starttime_5");
  static final STARTTIME_6 = amplify_core.QueryField(fieldName: "starttime_6");
  static final ENDTIME_1 = amplify_core.QueryField(fieldName: "endtime_1");
  static final ENDTIME_2 = amplify_core.QueryField(fieldName: "endtime_2");
  static final ENDTIME_3 = amplify_core.QueryField(fieldName: "endtime_3");
  static final ENDTIME_4 = amplify_core.QueryField(fieldName: "endtime_4");
  static final ENDTIME_5 = amplify_core.QueryField(fieldName: "endtime_5");
  static final ENDTIME_6 = amplify_core.QueryField(fieldName: "endtime_6");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ParticipantsDev";
    modelSchemaDefinition.pluralName = "ParticipantsDevs";
    
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
      key: ParticipantsDev.PHYSICALLY_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PHYSICALLY_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PHYSICALLY_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PHYSICALLY_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PHYSICALLY_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PHYSICALLY_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.EMOTIONALLY_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.INTENSITY_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LONELY_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.LEFT_OUT_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.SOCIAL_INTERACTION_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.UNDERSTOOD_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STRESSED_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.WHERE_YOU_ARE_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.PEOPLE_AROUND_YOU_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.STARTTIME_6,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_1,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_2,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_3,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_4,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_5,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ParticipantsDev.ENDTIME_6,
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

class _ParticipantsDevModelType extends amplify_core.ModelType<ParticipantsDev> {
  const _ParticipantsDevModelType();
  
  @override
  ParticipantsDev fromJson(Map<String, dynamic> jsonData) {
    return ParticipantsDev.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'ParticipantsDev';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [ParticipantsDev] in your schema.
 */
class ParticipantsDevModelIdentifier implements amplify_core.ModelIdentifier<ParticipantsDev> {
  final String id;

  /** Create an instance of ParticipantsDevModelIdentifier using [id] the primary key. */
  const ParticipantsDevModelIdentifier({
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
  String toString() => 'ParticipantsDevModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ParticipantsDevModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}