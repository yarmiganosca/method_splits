require 'minitest/autorun'

module MethodSplits
  def self.included(base)
    base.extend ClassMethods
  end
end

module MethodSplits
  module ClassMethods
    def split_method(method_name, entry_name, proxy_name)
      imethod = instance_method(method_name)

      entry, proxy = [entry_name, proxy_name].map.with_index do |name, index|
        arg = imethod.parameters[index].last

        {
          name: name,
          arg_string: "#{arg_prefix(imethod, arg)}#{arg}"
        }
      end

      class_eval <<-CLASS
        def #{entry[:name]}(#{entry[:arg_string]})
          #{proxy_class_name(imethod.name)}.new(self, #{entry[:arg_string]})
        end
      CLASS

      const_set(proxy_class_name(imethod.name), Class.new(MethodProxy)).class_eval <<-CLASS
        def #{proxy[:name]}(#{proxy[:arg_string]})
          host.#{imethod.name}(*host_args, #{proxy[:arg_string]})
        end
      CLASS
    end

    def proxy_class_name(method_name)
      camelized_method_name = method_name.to_s.split('_').map(&:capitalize).join('')

      "#{camelized_method_name}Proxy".to_sym
    end

    def arg_prefix(imethod, arg_name)
      case Hash[imethod.parameters.map(&:reverse)][arg_name]
      when :req # doesn't currently support optional parameters
        ""
      when :rest
        "*"
      when :block
        "&"
      end
    end
  end
end

module MethodSplits
  class MethodProxy
    def initialize(host, *host_args)
      @host      = host
      @host_args = host_args
    end
    attr_reader :host, :host_args
  end
end

describe MethodSplits do
  before do
    class PermissionSchema
      include MethodSplits

      def grant_rights(role_name, *right_names)
        [role_name, right_names]
      end

      split_method(:grant_rights, :role, :can)
    end
  end

  let(:permission_schema) { PermissionSchema.new }

  it "splits the method" do
    permission_schema.role(:user).can(:read, :create).must_equal [:user, [:read, :create]]
  end
end
