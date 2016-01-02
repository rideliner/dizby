# encoding: utf-8
# Copyright (c) 2016 Nathan Currier

class ConfigAccessHandler < YARD::Handlers::Ruby::AttributeHandler
  handles method_call(:config_reader)
  handles method_call(:config_writer)
  handles method_call(:config_accessor)
  namespace_only

  def access_permissions
    case statement.method_name(true)
    when :config_reader
      [true, false]
    when :config_writer
      [false, true]
    when :config_accessor
      [true, true]
    else
      [false, false]
    end
  end

  def process_impl(method, permission)
    if permission
      obj = MethodObject.new(namespace, method, scope)
      yield obj

      register(obj)
      obj
    else
      namespace.children.find do |o|
        o.name == method.to_sym && o.scope == scope
      end
    end
  end

  def store_obj(type, name, obj)
    namespace.attributes[scope][name][type] = obj if obj
  end

  def process_reader(attribute, permission)
    final = process_impl(attribute, permission) do |obj|
      obj.signature ||= "def #{attribute}"
      obj.source = "#{obj.signature}\n  @config[:#{attribute}]\nend"
      if obj.docstring.blank?(false)
        obj.docstring =
          "Returns the value of configuration attribute #{attribute}"
      end
    end

    store_obj :read, attribute, final
  end

  def process_writer(attribute, permission)
    final = process_impl("#{attribute}=", permission) do |obj|
      obj.parameters = [['value', nil]]
      obj.signature ||= "def #{attribute}=(value)"
      obj.source ||= "#{obj.signature}\n  @config[:#{attribute}] = value\nend"
      obj.docstring = <<-eos if obj.docstring.blank?(false)
          Sets the configuration attribute #{attribute}
          @param value the value to set the attribute #{attribute} to.
      eos
    end

    store_obj :write, attribute, final
  end

  def process_access(name)
    read, write = access_permissions
    namespace.attributes[scope][name] ||= SymbolHash[read: nil, write: nil]

    process_reader(name, read)
    process_writer(name, write)
  end

  def process
    return if statement.type == :var_ref || statement.type == :vcall
    params = statement.parameters(false).dup

    validated_attribute_names(params).each do |name|
      process_access(name)
    end
  end
end
