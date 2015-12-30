
class ConfigAccessHandler < YARD::Handlers::Ruby::AttributeHandler
  handles method_call(:config_reader)
  handles method_call(:config_writer)
  handles method_call(:config_accessor)
  namespace_only

  def process
    return if statement.type == :var_ref || statement.type == :vcall
    read, write = true, false
    params = statement.parameters(false).dup

    case statement.method_name(true)
    when :config_reader
      # change nothing
    when :config_writer
      read, write = false, true
    when :config_accessor
      write = true
    end

    validated_attribute_names(params).each do |name|
      namespace.attributes[scope][name] ||= SymbolHash[read: nil, write: nil]

      {read: name, write: "#{name}="}.each do |type, method|
        if (type == :read ? read : write)
          o = MethodObject.new(namespace, method, scope)
          if type == :write
            o.parameters = [['value', nil]]
            src = "def #{method}(value)"
            full_src = "#{src}\n  @#{name} = value\nend"
            doc = "Sets the configuration attribute #{name}\n@param value the value to set the attribute #{name} to."
          else
            src = "def #{method}"
            full_src = "#{src}\n  @#{name}\nend"
            doc = "Returns the value of configuration attribute #{name}"
          end

          o.source ||= full_src
          o.signature ||= src
          register(o)
          o.docstring = doc if o.docstring.blank?(false)

          namespace.attributes[scope][name][type] = o
        elsif obj = namespace.children.find { |o| o.name == method.to_sym && o.scope == scope }
          namespace.attributes[scope][name][type] = obj
        end
      end
    end
  end
end
