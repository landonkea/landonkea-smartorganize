# lib/smartorganize.rb
#
# This is the MAIN MODULE file — the "front door" of the library.
# When someone writes "require 'smartorganize'", Ruby loads THIS file.
# It then loads everything else the tool needs.
#
# Think of this file as a table of contents: it lists all the parts
# of the program in the order they're needed.
module SmartOrganize
  # --- Load all the parts of the program ---
  # require_relative loads files in a specific order:
  # 1. version.rb — so VERSION is available everywhere
  # 2. config.rb — so we can read the user's settings
  # 3. organizer.rb — so we can organize files
  # 4. cli.rb — so we can handle command-line input
  require_relative "smartorganize/version"
  require_relative "smartorganize/color"
  require_relative "smartorganize/config"
  require_relative "smartorganize/organizer"
  require_relative "smartorganize/cli"
end
