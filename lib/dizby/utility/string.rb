# Copyright (c) 2016 Nathan Currier

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module Dizby
  def self.any_to_s(obj)
    "#{obj}:#{obj.class}"
  rescue
    format '#<%s:0x%1x>', obj.class, obj.__id__
  end
end
