#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_test;

import 'package:protobuf/protobuf.dart';
import 'package:unittest/unittest.dart';

import '../out/protos/google/protobuf/unittest.pb.dart';

import 'test_util.dart';

void main() {
  final String TEST_ALL_TYPES_JSON = '{"1":101,"2":102,"3":103,"4":104,'
      '"5":105,"6":106,"7":107,"8":108,"9":109,"10":110,"11":111.0,'
      '"12":112.0,"13":true,"14":"115","15":"MTE2","16":{"17":117},'
      '"18":{"1":118},"19":{"1":119},"20":{"1":120},"21":3,"22":6,"23":9,'
      '"24":"124","25":"125","31":[201,301],"32":[202,302],'
      '"33":[203,303],"34":[204,304],"35":[205,305],"36":[206,306],'
      '"37":[207,307],"38":[208,308],"39":[209,309],"40":[210,310],'
      '"41":[211.0,311.0],"42":[212.0,312.0],"43":[true,false],'
      '"44":["215","315"],"45":["MjE2","MzE2"],"46":[{"47":217},{"47":317}],'
      '"48":[{"1":218},{"1":318}],"49":[{"1":219},{"1":319}],'
      '"50":[{"1":220},{"1":320}],"51":[2,3],"52":[5,6],"53":[8,9],'
      '"54":["224","324"],"55":["225","325"],"61":401,"62":402,"63":403,'
      '"64":404,"65":405,"66":406,"67":407,"68":408,"69":409,'
      '"70":410,"71":411.0,"72":412.0,"73":false,"74":"415","75":"NDE2",'
      '"81":1,"82":4,"83":7,"84":"424","85":"425"}';

  /**
   * Checks that message once serialized to JSON
   * matches TEST_ALL_TYPES_JSON massaged with [:.replaceAll(from, to):].
   */
  expectedJson(from, to) {
    var expectedJson = TEST_ALL_TYPES_JSON.replaceAll(from, to);
    return predicate(
        (message) => message.writeToJson() == expectedJson, 'Incorrect output');
  }

  test('testOutput', () {
    expect(getAllSet().writeToJson(), TEST_ALL_TYPES_JSON);

    // Test empty list.
    expect(getAllSet()..repeatedBool.clear(),
           expectedJson('"43":[true,false],', ''));

    // Test negative number.
    expect(getAllSet()..optionalInt32 = -1234567,
           expectedJson(':101,', ':-1234567,'));

    // 64-bit numbers outside 53-bit range are quoted.
    expect(getAllSet()..optionalInt64 = make64(0, 0x200000),
           expectedJson(':102,', ':9007199254740992,'));
    expect(getAllSet()..optionalInt64 = make64(1, 0x200000),
           expectedJson(':102,', ':"9007199254740993",'));
    expect(getAllSet()..optionalInt64 = -make64(0, 0x200000),
           expectedJson(':102,', ':-9007199254740992,'));
    expect(getAllSet()..optionalInt64 = -make64(1, 0x200000),
           expectedJson(':102,', ':"-9007199254740993",'));

    // Quotes, backslashes, and control characters in strings are quoted.
    expect(getAllSet()..optionalString = 'a\u0000b\u0001cd\\e\"fg',
           expectedJson(':"115",', ':"a\\u0000b\\u0001cd\\\\e\\"fg",'));
  });

  test('testBase64Encode', () {
    expect(getAllSet()..optionalBytes = 'Hello, world'.codeUnits,
           expectedJson(':"MTE2",', ':"SGVsbG8sIHdvcmxk",'));

    expect(getAllSet()..optionalBytes = 'Hello, world!'.codeUnits,
           expectedJson(':"MTE2",', ':"SGVsbG8sIHdvcmxkIQ==",'));

    expect(getAllSet()..optionalBytes = 'Hello, world!!'.codeUnits,
           expectedJson(':"MTE2",', ':"SGVsbG8sIHdvcmxkISE=",'));

    // An empty list should not appear in the output.
    expect(getAllSet()..optionalBytes = [], expectedJson('"15":"MTE2",', ''));

    expect(getAllSet()..optionalBytes = 'a'.codeUnits,
           expectedJson(':"MTE2",', ':"YQ==",'));
  });

  test('testBase64Decode', () {
    optionalBytes(from, to) {
      String json = TEST_ALL_TYPES_JSON.replaceAll(from, to);
      return new String.fromCharCodes(
          new TestAllTypes.fromJson(json).optionalBytes);
    }

    expect(optionalBytes(':"MTE2",', ':"SGVsbG8sIHdvcmxk",'), 'Hello, world');

    var json, message;

    expect(optionalBytes(':"MTE2",', ':"SGVsbG8sIHdvcmxkIQ==",'),
           'Hello, world!');

    expect(optionalBytes(':"MTE2",', ':"SGVsbG8sIHdvcmxkISE=",'),
           'Hello, world!!');

    // Remove optionalBytes tag, reads back as empty list, hence empty string.
    expect(optionalBytes('"15":"MTE2",', ''), isEmpty);

    // Keep optionalBytes tag, set data to empty string, get back empty list.
    expect(optionalBytes(':"MTE2",', ':"",'), isEmpty);

    expect(optionalBytes(':"MTE2",', ':"YQ==",'), 'a');
  });

  test('testParse', () {
    expect(new TestAllTypes.fromJson(TEST_ALL_TYPES_JSON), getAllSet());
  });

  test('testExtensionsOutput', () {
    expect(getAllExtensionsSet().writeToJson(), TEST_ALL_TYPES_JSON);
  });

  test('testExtensionsParse', () {
    ExtensionRegistry registry = getExtensionRegistry();
    expect(new TestAllExtensions.fromJson(TEST_ALL_TYPES_JSON, registry),
           getAllExtensionsSet());
  });
}
