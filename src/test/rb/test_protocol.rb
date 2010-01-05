require 'test_help'

class TestProtocol < Test::Unit::TestCase

  class ExampleProtocol
    attr_reader :protocol_string, :valid, :name
    attr_accessor :comment
    def initialize(protocol_string, name=nil, comment='')
      @protocol_string = protocol_string
      @name = name || protocol_string # default to schema_string for name
      @comment = comment
    end
  end
#
# Example Protocols
#

EXAMPLES = [
  ExampleProtocol.new(<<-EOS, true),
{
  "namespace": "com.acme",
  "protocol": "HelloWorld",

  "types": [
    {"name": "Greeting", "type": "record", "fields": [
      {"name": "message", "type": "string"}]},
    {"name": "Curse", "type": "error", "fields": [
      {"name": "message", "type": "string"}]}
  ],

  "messages": {
    "hello": {
      "request": [{"name": "greeting", "type": "Greeting" }],
      "response": "Greeting",
      "errors": ["Curse"]
    }
  }
}
EOS

  ExampleProtocol.new(<<-EOS, true),
{"namespace": "org.apache.avro.test",
 "protocol": "Simple",

 "types": [
     {"name": "Kind", "type": "enum", "symbols": ["FOO","BAR","BAZ"]},

     {"name": "MD5", "type": "fixed", "size": 16},

     {"name": "TestRecord", "type": "record",
      "fields": [
          {"name": "name", "type": "string", "order": "ignore"},
          {"name": "kind", "type": "Kind", "order": "descending"},
          {"name": "hash", "type": "MD5"}
      ]
     },

     {"name": "TestError", "type": "error", "fields": [
         {"name": "message", "type": "string"}
      ]
     }

 ],

 "messages": {

     "hello": {
         "request": [{"name": "greeting", "type": "string"}],
         "response": "string"
     },

     "echo": {
         "request": [{"name": "record", "type": "TestRecord"}],
         "response": "TestRecord"
     },

     "add": {
         "request": [{"name": "arg1", "type": "int"}, {"name": "arg2", "type": "int"}],
         "response": "int"
     },

     "echoBytes": {
         "request": [{"name": "data", "type": "bytes"}],
         "response": "bytes"
     },

     "error": {
         "request": [],
         "response": "null",
         "errors": ["TestError"]
     }
 }

}
EOS
  ExampleProtocol.new(<<-EOS, true),
{"namespace": "org.apache.avro.test.namespace",
 "protocol": "TestNamespace",

 "types": [
     {"name": "org.apache.avro.test.util.MD5", "type": "fixed", "size": 16},
     {"name": "TestRecord", "type": "record",
      "fields": [ {"name": "hash", "type": "org.apache.avro.test.util.MD5"} ]
     },
     {"name": "TestError", "namespace": "org.apache.avro.test.errors",
      "type": "error", "fields": [ {"name": "message", "type": "string"} ]
     }
 ],

 "messages": {
     "echo": {
         "request": [{"name": "record", "type": "TestRecord"}],
         "response": "TestRecord"
     },

     "error": {
         "request": [],
         "response": "null",
         "errors": ["org.apache.avro.test.errors.TestError"]
     }

 }

}
EOS
  ExampleProtocol.new(<<-EOS, true)
{"namespace": "org.apache.avro.test",
 "protocol": "BulkData",

 "types": [],

 "messages": {

     "read": {
         "request": [],
         "response": "bytes"
     },

     "write": {
         "request": [ {"name": "data", "type": "bytes"} ],
         "response": "null"
     }

 }

}
EOS
]

  Protocol = Avro::Protocol
  def test_parse
    EXAMPLES.each do |example|
      assert_nothing_raised("should be valid: #{example.protocol_string}") {
        Protocol.parse(example.protocol_string)
      }
    end
  end

  def test_valid_cast_to_string_after_parse
    EXAMPLES.each do |example|
      assert_nothing_raised("round tripped okay #{example.protocol_string}") {
        foo = Protocol.parse(example.protocol_string).to_s
        Protocol.parse(foo)
      }
    end
  end

  def test_equivalence_after_round_trip
    EXAMPLES.each do |example|
      original = Protocol.parse(example.protocol_string)
      round_trip = Protocol.parse(original.to_s)

      assert_equal original, round_trip
    end
  end
end
