module Avro
  class Protocol
    VALID_TYPE_SCHEMA_TYPES = Set.new(%w[enum record error fixed])
    class ProtocolParseError < Avro::AvroError; end

    attr_reader :name, :namespace, :types, :messages, :md5
    def self.parse(protocol_string)
      json_data = Yajl.load(protocol_string)

      if json_data.is_a? Hash
        name = json_data['protocol']
        namespace = json_data['namespace']
        types = json_data['types']
        messages = json_data['messages']
        Protocol.new(name, namespace, types, messages)
      else
        raise ProtocolParseError, "Not a JSON object: #{json_data}"
      end
    end

    def initialize(name, namespace=nil, types=nil, messages=nil)
      # Ensure valid ctor args
      if !name
        raise ProtocolParseError, 'Protocols must have a non-empty name.'
      elsif !name.is_a?(String)
        raise ProtocolParseError, 'The name property must be a string.'
      elsif !namespace.is_a?(String)
        raise ProtocolParseError, 'The namespace property must be a string.'
      elsif !types.is_a?(Array)
        raise ProtocolParseError, 'The types property must be a list.'
      elsif !messages.is_a?(Hash)
        raise ProtocolParseError, 'The messages property must be a JSON object.'
      end

      @name = name
      @namespace = namespace
      type_names = {}
      @types = parse_types(types, type_names)
      @messages = parse_messages(messages, type_names)
      @md5 = Digest::MD5.digest(to_s)
    end

    def to_s
      Yajl.dump to_hash
    end

    def ==(other)
      to_hash == Yajl.load(other.to_s)
    end

    private
    def parse_types(types, type_names)
      type_objects = []
      types.collect do |type|
        # FIXME adding type.name to type_names is not defined in the
        # spec. Possible bug in the python impl and the spec.
        type_object = Schema.real_parse(type, type_names)
        unless VALID_TYPE_SCHEMA_TYPES.include?(type_object.type)
          msg = "Type #{type} not an enum, record, fixed or error."
          raise ProtocolParseError, msg
        end
        type_object
      end
    end

    def parse_messages(messages, names)
      message_objects = {}
      messages.each do |name, body|
        if message_objects.has_key?(name)
          raise ProtocolParseError, "Message name \"#{name}\" repeated."
        elsif !body.is_a?(Hash)
          raise ProtocolParseError, "Message name \"#{name}\" has non-object body #{body.inspect}"
        end

        request  = body['request']
        response = body['response']
        errors   = body['errors']
        message_objects[name] = Message.new(name, request, response, errors, names)
      end
      message_objects
    end

    def to_hash
      hsh = {'protocol' => name}
      hsh['namespace'] = namespace if namespace
      hsh['types'] = types.map{|t| Yajl.load(t.to_s) } if types

      if messages
        hsh['messages'] = messages.collect_hash{|k,t| [k, Yajl.load(t.to_s)] }
      end

      hsh
    end

    class Message
      attr_reader :name, :response_from_names, :request, :response, :errors
      def initialize(name, request, response, errors=nil, names=nil)
        @name = name
        @response_from_names = false

        @request = parse_request(request, names)
        @response = parse_response(response, names)
        @errors = parse_errors(errors, names) if errors
      end

      def to_s
        hsh = {'request' => request.map{|r| Yajl.load(r.to_s) }}
        if response_from_names
          hsh['response'] = response.fullname
        else
          hsh['response'] = Yajl.load(response.to_s)
        end

        if errors
          hsh['errors'] = Yajl.load(errors.to_s)
        end
        Yajl.dump hsh
      end

      def parse_request(request, names)
        unless request.is_a?(Array)
          raise ProtocolParseError, "Request property not an Array: #{request.inspect}"
        end
        Schema::RecordSchema.make_field_objects(request, names)
      end

      def parse_response(response, names)
        if response.is_a?(String) && names[response]
          @response_from_names = true
          names[response]
        else
          Schema.real_parse(response, names)
        end
      end

      def parse_errors(errors, names)
        unless errors.is_a?(Array)
          raise ProtocolParseError, "Errors property not an Array: #{errors}"
        end
        Schema.real_parse(errors, names)
      end
    end
  end
end
