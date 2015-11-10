
require 'ipaddr'

module Dirby
  class ACL
    class Entry
      def initialize(str)
        if str == '*' || str == 'all'
          @access = [ :all ]
        elsif str.include?('*')
          @access = [ :name, pattern(str) ]
        else
          begin
            @access = [ :ip, IPAddr.new(str) ]
          rescue ArgumentError
            @access = [ :name, pattern(str) ]
          end
        end
      end

      def matches?(addr)
        case @access.first
        when :all
          true
        when :ip
          begin
            ipaddr = IPAddr.new(addr[3])
            # map to ipv6 if entry is ipv6 and address is ipv4
            ipaddr = ipaddr.ipv4_mapped if @access.last.ipv6? && ipaddr.ipv4?
          rescue ArgumentError
            return false
          end

          @access.last.include?(ipaddr)
        when :name
          @access.last =~ addr[2]
        else
          false
        end
      end

      private

      def pattern(str)
        p = str.split('.').map { |s|
          (s == '*') ? '.+' : s
        }.join('\\.')
        /^#{p}$/
      end
    end

    class List < Array
      def matches?(addr)
        any? { |entry|
          entry.matches?(addr)
        }
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
        return true if @allow.matches?(addr)
        return false if @deny.matches?(addr)
        true
      when :allow_deny
        return false if @deny.matches?(addr)
        return true if @allow.matches?(addr)
        false
      else
        false
      end
    end

    def install_list(list)
      Hash[*list].each { |permission, domain|
        case permission.downcase
        when 'allow'
          @allow.push(domain)
        when 'deny'
          @deny.push(domain)
        else
          raise "Invalid ACL entry #{list.to_s}"
        end
      }
    end
  end
end

=begin To allow unless explicitly denied

acl = DRb::ACL.new(:allow_deny)
acl.install_list %w[ allow all ]
acl.install_list your_list_of_denies

=end

=begin To deny unless explicitly allowed

acl = DRb::ACL.new(:deny_allow)
acl.install_list %w[ deny all ]
acl.install_list your_list_of_allows

=end