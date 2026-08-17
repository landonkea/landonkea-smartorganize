# lib/smartorganize/cli.rb
#
# This is the USER INTERFACE, the part that talks to the human.
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
      # Example: smartorganize organize ~/Downloads --dry-run
      #   @args = ["organize", "~/Downloads", "--dry-run"]
      @args = args

      # @flags stores command-line options (flags start with "--" or "-")
      # These modify HOW a command runs, not WHAT command runs.
      # Example: --dry-run, --verbose, --quiet
      @flags = []

      # @directory stores the directory path (if provided)
      # This is the WHERE, which folder to act on.
      @directory = nil
    end

    # --- run: the main entry point ---
    # This method is called from bin/smartorganize.
    # It decides what to do based on the first argument.
    def run
      # STEP 1: Separate flags from the command and directory
      parse_args

      # STEP 2: If no command was given, show help
      if @args.empty?
        show_help
        return
      end

      # STEP 3: Get the command (first remaining argument)
      command = @args.shift

      # STEP 4: Get the directory (if provided)
      @directory = @args.first || "."

      # STEP 5: Run the command
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
        # Unknown command, show error in RED and help in normal
        warn Color.red("Error: Unknown command '#{command}'")
        warn
        show_help
      end
    end

    private

    # --- parse_args: separates flags from commands ---
    # This method goes through @args and pulls out any flags.
    # Flags are words that start with "-" (like --dry-run or -v).
    # Commands and directories are everything else.
    #
    # After parsing:
    #   @flags = ["--dry-run", "--verbose"]
    #   @args = ["organize", "~/Downloads"]
    #
    def parse_args
      # We need to loop through @args and collect ALL flags,
      # even if they come after the directory.
      #
      # Strategy: Go through each argument. If it starts with "-",
      # it's a flag. Otherwise, it's a command/directory.
      #
      # We use a new array to collect non-flag arguments.
      non_flags = []

      while @args.any?
        arg = @args.shift  # Remove the first element

        if arg.start_with?("-")
          # It's a flag, add to @flags
          @flags.push(arg)
        else
          # It's not a flag, add to non_flags
          non_flags.push(arg)
        end
      end

      # Put the non-flag arguments back in @args
      # Now @args only contains the command and directory
      @args = non_flags
    end

    # --- Flag helpers ---
    # These methods check if a specific flag was provided.

    def dry_run?
      # .any? with a block checks if ANY element in the array
      # matches the condition. Returns true or false.
      @flags.any? { |f| f == "--dry-run" }
    end

    def verbose?
      @flags.any? { |f| f == "--verbose" || f == "-v" }
    end

    def force?
      @flags.any? { |f| f == "--force" || f == "-f" }
    end

    def quiet?
      @flags.any? { |f| f == "--quiet" || f == "-q" }
    end

    def recursive?
      @flags.any? { |f| f == "--recursive" || f == "-r" }
    end

    # --- Command methods ---
    # Each "cmd_" method handles one command from the user.

    # cmd_init: creates a default config file in the current directory.
    def cmd_init
      config_path = File.join(Dir.pwd, ".smartorganize.yml")

      if File.exist?(config_path) && !force?
        puts Color.yellow("Config file already exists at #{config_path}")
        return
      end

      # Create a default config and write it to disk
      config = Config.new
      File.write(config_path, config.to_yaml)
      puts Color.green("Created config file: #{config_path}")
      puts Color.dim("Edit it to customize your categories.")
    end

    # cmd_scan: shows what would be organized (dry run).
    def cmd_scan
      config = Config.new
      organizer = Organizer.new(@directory, config, recursive: recursive?, quiet: quiet?)

      unless quiet?
        puts Color.blue("Scanning #{File.expand_path(@directory)}...")
        puts
      end
      organizer.stats
    end

    # cmd_organize: actually organizes files.
    def cmd_organize
      config = Config.new
      organizer = Organizer.new(@directory, config, recursive: recursive?, quiet: quiet?)

      if dry_run?
        # Dry run mode, show what WOULD happen, don't actually do it
        unless quiet?
          puts Color.blue("DRY RUN, no files will be moved")
          puts
        end
        organizer.stats
        return
      end

      # Normal mode, ask for confirmation first, unless --force was used.
      # This is a separate method (confirmed?) rather than inline code here,
      # because "does the user want to proceed?" is its own single question,
      # keeping it out of cmd_organize keeps this method focused on ONE thing:
      # deciding which of the three modes (dry-run / confirm / force) to run.
      return unless force? || confirmed?(organizer)

      organizer.organize
    end

    # confirmed?: shows the plan and asks "Proceed? (y/n)".
    # Returns true if the user typed "y" or "yes", false otherwise
    # (including if they cancelled or pressed Ctrl+D).
    def confirmed?(organizer)
      puts Color.blue("This will organize files in #{File.expand_path(@directory)}")
      puts
      organizer.stats
      puts
      print Color.yellow("Proceed? (y/n): ")

      # gets reads a line of input from the user (until they press Enter)
      # .chomp removes the trailing newline character
      # WHY? When you type "y" and press Enter, gets returns "y\n"
      # The \n is the newline. .chomp removes it, leaving just "y"
      #
      # &. is the "safe navigation operator" (also called "nil-safe dot")
      # It works like . but returns nil if the thing before it is nil.
      # If gets returns nil (user pressed Ctrl+D or closed terminal),
      # gets&.chomp returns nil instead of crashing.
      #
      # .downcase converts to lowercase: "Y" becomes "y", "Yes" becomes "yes"
      #
      answer = gets&.chomp&.downcase
      proceed = answer == "y" || answer == "yes"
      puts(proceed ? "" : Color.yellow("Cancelled."))
      proceed
    end

    # cmd_undo: reverses the last organize operation.
    def cmd_undo
      config = Config.new
      organizer = Organizer.new(@directory, config, recursive: recursive?, quiet: quiet?)
      organizer.undo
    end

    # cmd_stats: shows statistics about the folder.
    def cmd_stats
      config = Config.new
      organizer = Organizer.new(@directory, config, recursive: recursive?, quiet: quiet?)
      organizer.stats
    end

    # --- Help and version ---

    # show_help: prints usage instructions.
    # The <<~HEREDOC syntax creates a multi-line string.
    # The "~" strips leading whitespace, so the output is clean.
    def show_help
      puts <<~HELP
        #{Color.bold("smartorganize v#{VERSION}")}, automatically organize files by type

        #{Color.bold("Usage:")}
          smartorganize <command> [directory] [options]

        #{Color.bold("Commands:")}
          #{Color.green("init")} [--force]           Create a config file in the current directory
          #{Color.blue("scan")} [directory]        Show what would be organized (dry run)
          #{Color.green("organize")} [directory]    Actually organize the files
          #{Color.yellow("undo")} [directory]        Reverse the last organization
          #{Color.blue("stats")} [directory]       Show file statistics
          #{Color.dim("help")}                    Show this help message
          #{Color.dim("version")}                 Show version number

        #{Color.bold("Options:")}
          #{Color.yellow("--dry-run")}             Show what would happen without doing it
          #{Color.yellow("--verbose")}             Show more details
          #{Color.yellow("--force")}               Skip confirmation prompt
          #{Color.yellow("--quiet")}               Suppress output
          #{Color.yellow("--recursive")}           Scan subfolders too

        #{Color.bold("Examples:")}
          smartorganize scan ~/Downloads
          smartorganize organize ~/Downloads --dry-run
          smartorganize organize ~/Downloads --force --quiet
          smartorganize organize ~/Downloads --recursive
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
