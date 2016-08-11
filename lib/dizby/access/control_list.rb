# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require 'dizby/access/entry'
require 'dizby/access/list'

module Dizby
  module Access
    class ControlList
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
          domain = Entry.new(domain)
          case permission.downcase
          when 'allow'
            @allow.push(domain)
          when 'deny'
            @deny.push(domain)
          else
            raise ArgumentError, "Invalid ACL entry #{list}"
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
end

# !! To allow unless explicitly denied
# acl = Dizby::Access::ControlList.new(:allow_deny)
# acl.install_list %w[ allow all ]
# acl.install_list your_list_of_denies

# !! To deny unless explicitly allowed
# acl = Dizby::Access::ControlList.new(:deny_allow)
# acl.install_list %w[ deny all ]
# acl.install_list your_list_of_allows
