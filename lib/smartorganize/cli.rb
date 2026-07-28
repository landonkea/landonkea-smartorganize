# lib/smartorganize/cli.rb
#
# This is the USER INTERFACE — the part that talks to the human.
# It reads what the user typed, figures out what they want to do,
# and calls the right Organizer method.
#
# Every CLI program follows this pattern:
# 1. Parse what the user typed
# 2. Validate the input
# 3. Do the work (call the logic)
# 4. Print the result

module SmartOrganize
  # --- CLI class ---
  # Handles all interaction with the terminal user.
  class CLI
    # --- Initialize ---
    # Takes ARGV (the command-line arguments array).
    def initialize(args)
      # @args is the list of words the user typed after "smartorganize"
      # Example: smartorganize organize ~/Downloads
      #   @args = ["organize", "~/Downloads"]
      @args = args
    end

    # --- run: the main entry point ---
    # This method is called from bin/smartorganize.
    # It decides what to do based on the first argument.
    def run
      # If the user didn't type any command, show help
      if @args.empty?
        show_help
        return
      end

      # .shift removes and returns the FIRST element of the array.
      # After this, @args only contains the remaining arguments.
      #
      # Example:
      #   Before: @args = ["organize", "~/Downloads"]
      #   After:  command = "organize", @args = ["~/Downloads"]
      command = @args.shift

      # case/when is Ruby's switch statement.
      # Each "when" checks if the command matches a string.
      # The "else" handles unknown commands.
      case command
      when "init"
        cmd_init
      when "scan"
        cmd_scan
      when "organize"
        cmd_organize
      when "undo"
        cmd_undo
      when "stats"
        cmd_stats
      when "help", "--help", "-h"
        show_help
      when "version", "--version", "-v"
        show_version
      else
        # Unknown command — show error and help
        warn "Unknown command: #{command}"
        warn
        show_help
      end
    end

    private

    # --- Command methods ---
    # Each "cmd_" method handles one command from the user.

    # cmd_init: creates a default config file in the current directory.
    def cmd_init
      config_path = File.join(Dir.pwd, ".smartorganize.yml")

      if File.exist?(config_path)
        puts "Config file already exists at #{config_path}"
        return
      end

      # Create a default config and write it to disk
      config = Config.new
      File.write(config_path, config.to_yaml)
      puts "Created config file: #{config_path}"
      puts "Edit it to customize your categories."
    end

    # cmd_scan: shows what would be organized (dry run).
    def cmd_scan
      directory = @args.first || "."
      config = Config.new
      organizer = Organizer.new(directory, config)

      puts "Scanning #{File.expand_path(directory)}..."
      puts
      organizer.stats
    end

    # cmd_organize: actually organizes files.
    def cmd_organize
      directory = @args.first || "."
      config = Config.new
      organizer = Organizer.new(directory, config)
      organizer.organize
    end

    # cmd_undo: reverses the last organize operation.
    def cmd_undo
      directory = @args.first || "."
      config = Config.new
      organizer = Organizer.new(directory, config)
      organizer.undo
    end

    # cmd_stats: shows statistics about the folder.
    def cmd_stats
      directory = @args.first || "."
      config = Config.new
      organizer = Organizer.new(directory, config)
      organizer.stats
    end

    # --- Help and version ---

    # show_help: prints usage instructions.
    # The <<~HEREDOC syntax creates a multi-line string.
    # The "~" strips leading whitespace, so the output is clean.
    def show_help
      puts <<~HELP
        smartorganize v#{VERSION} — automatically organize files by type

        Usage:
          smartorganize <command> [directory]

        Commands:
          init                    Create a config file in the current directory
          scan [directory]        Show what would be organized (dry run)
          organize [directory]    Actually organize the files
          undo [directory]        Reverse the last organization
          stats [directory]       Show file statistics
          help                    Show this help message
          version                 Show version number

        Examples:
          smartorganize scan ~/Downloads
          smartorganize organize ~/Downloads
          smartorganize undo ~/Downloads

        If no directory is given, uses the current folder.
      HELP
    end

    # show_version: prints the version number.
    def show_version
      puts "smartorganize v#{VERSION}"
    end
  end
end
