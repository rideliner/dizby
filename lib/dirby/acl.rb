
require 'ipaddr'

module Dirby
  class ACL
    class Entry
      def initialize(str)
        if str == '*' || str == 'all'
          @access = [:all]
        elsif str.include?('*')
          @access = [:name, pattern(str)]
        else
          begin
            @access = [:ip, IPAddr.new(str)]
          rescue ArgumentError
            @access = [:name, pattern(str)]
          end
        end
      end

      def matches?(addr)
        (scope, pattern) = @access

        case scope
        when :all
          true
        when :ip
          matches_ip?(addr, pattern)
        when :name
          matches_name?(addr, pattern)
        else
          false
        end
      end

      class << self
        private

        def pattern(str)
          pattern = str.split('.')
          pattern.map! { |segment| (segment == '*') ? '.+' : segment }
          /^#{pattern.join('\\.')}$/
        end

        def matches_ip?(addr, pattern)
          ipaddr = IPAddr.new(addr[3])
          # map to ipv6 if entry is ipv6 and address is ipv4
          ipaddr = ipaddr.ipv4_mapped if pattern.ipv6? && ipaddr.ipv4?

          pattern.include?(ipaddr)
        rescue ArgumentError
          false
        end

        def matches_name?(addr, pattern)
          pattern =~ addr[2]
        end
      end
    end

    class List < Array
      def matches?(addr)
        any? { |entry| entry.matches?(addr) }
      end
    end

    # :deny_allow
    # if allowed, allow
    # else if denied, deny
    # else, allow

    # :allow_deny
    # if denied, deny
    # else if allowed, allow
    # else, deny

    def initialize(order = :deny_allow)
      @order = order
      @deny = List.new
      @allow = List.new
    end

    def allow_socket?(soc)
      allow_addr?(soc.peeraddr)
    end

    def allow_addr?(addr)
      case @order
      when :deny_allow
        deny_allow?(addr)
      when :allow_deny
        allow_deny?(addr)
      else
        false
      end
    end

    def install_list(list)
      Hash[*list].each do |permission, domain|
        case permission.downcase
        when 'allow'
          @allow.push(domain)
        when 'deny'
          @deny.push(domain)
        else
          raise "Invalid ACL entry #{list}"
        end
      end
    end

    private

    def deny_allow?(addr)
      return true if @allow.matches?(addr)
      return false if @deny.matches?(addr)
      true
    end

    def allow_deny?(addr)
      return false if @deny.matches?(addr)
      return true if @allow.matches?(addr)
      false
    end
  end
end

# !! To allow unless explicitly denied
# acl = Dirby::ACL.new(:allow_deny)
# acl.install_list %w[ allow all ]
# acl.install_list your_list_of_denies

# !! To deny unless explicitly allowed
# acl = Dirby::ACL.new(:deny_allow)
# acl.install_list %w[ deny all ]
# acl.install_list your_list_of_allows
