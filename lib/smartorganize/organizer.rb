# lib/smartorganize/organizer.rb
#
# This is the CORE LOGIC, the engine that actually organizes files.
# Everything else (CLI, config) exists to support this class.
#
# The Organizer class:
# 1. Scans a directory for files
# 2. Categorizes each file by its extension
# 3. Moves files into subfolders
# 4. Keeps a log so you can undo changes

require "fileutils"
require "json"
require "time"

module SmartOrganize
  # --- Organizer class ---
  # This is where the real work happens.
  # Each Organizer object is tied to ONE directory (the one you're organizing).
  class Organizer
    # UNITS is a CONSTANT, a value that never changes.
    # WHY is it ALL_CAPS? Because that's Ruby convention.
    # Variables use lowercase: my_variable
    # Constants use UPPERCASE: UNITS
    #
    # A constant is like a variable, but Ruby warns you if you try
    # to change it. It's a way to say "this value is fixed."
    #
    # UNITS is an ARRAY of strings: ["B", "KB", "MB", "GB", "TB"]
    # Each element is a unit of measurement, from smallest to largest.
    # We use this in format_size to convert bytes to human-readable text.
    #
    UNITS = ["B", "KB", "MB", "GB", "TB"].freeze

    # --- Initialize ---
    # Takes a directory path and a Config object.
    def initialize(directory, config, recursive: false)
      # File.expand_path converts relative paths to absolute paths.
      # "~/Downloads" becomes "/Users/yourname/Downloads"
      @directory = File.expand_path(directory)
      @config = config
      @recursive = recursive

      # @log_file is where we record every move we make.
      # This is how "undo" works, we read the log backwards.
      @log_file = File.join(@directory, ".smartorganize.log")

      # @moved_files tracks what we move in this session.
      # It starts as an empty array, we'll push each move into it.
      @moved_files = []
    end

    # --- Public methods ---

    # scan: looks at all files and shows what WOULD be moved.
    # This is the "dry run", nothing actually changes on disk.
    #
    # Returns an array of hashes, each describing one file's fate.
    def scan
      if @recursive
        scan_recursive(@directory)
      else
        scan_directory(@directory)
      end
    end

    # organize: actually moves files into categorized subfolders.
    # This is the "real" action, files WILL be moved on disk.
    #
    # Returns a summary of what was done.
    def organize
      # Get the scan results first
      plan = scan

      # If nothing to organize, say so and return early
      if plan.empty?
        puts Color.green("Nothing to organize, folder is already clean!")
        return { moved: 0, categories: {} }
      end

      # Print what we're about to do
      puts Color.blue("Organizing #{plan.length} files...")
      puts

      # Track statistics for the summary
      stats = { moved: 0, categories: {}, total_size: 0 }

      # Process each file in the plan
      plan.each do |file|
        # Create the category subfolder if it doesn't exist
        # FileUtils.mkdir_p creates the folder AND any parent folders
        # that don't exist yet. "-p" means "make parent directories".
        category_dir = File.join(@directory, file[:category])
        FileUtils.mkdir_p(category_dir)

        # Move the file
        # FileUtils.mv is like the "mv" shell command.
        # It moves a file from one location to another.
        #
        # The rescue block catches errors (like "file already exists")
        # and prints a warning instead of crashing.
        begin
          FileUtils.mv(file[:source], file[:destination])

          # Record this move in our log (for undo)
          @moved_files.push(
            from: file[:destination],
            to: file[:source],
            timestamp: Time.now.iso8601,
          )

          # Update statistics
          stats[:moved] += 1
          stats[:categories][file[:category]] ||= 0
          stats[:categories][file[:category]] += 1
          stats[:total_size] += file[:size]

          # Print what we did
          puts Color.green("  #{file[:filename]} -> #{file[:category]}/")

        rescue Errno::EEXIST => e
          # This error means a file with the same name already exists
          # in the destination. We skip it rather than overwriting.
          warn Color.yellow("  SKIP: #{file[:filename]} (already exists in #{file[:category]}/)")
        rescue StandardError => e
          # Any other error, print the message and continue
          warn Color.red("  ERROR: #{file[:filename]}, #{e.message}")
        end
      end

      # Save the log file so "undo" can work later
      save_log

      # Print summary
      puts
      puts Color.green("Done! Moved #{stats[:moved]} files (#{format_size(stats[:total_size])}).")
      stats[:categories].each do |category, count|
        puts Color.dim("  #{category}: #{count} files")
      end

      stats
    end

    # undo: reverses the last organize operation.
    # It reads the log file and moves everything back.
    def undo
      # Check if there's a log file to undo
      unless File.exist?(@log_file)
        puts Color.yellow("Nothing to undo, no log file found.")
        return
      end

      # Read the log file and parse it as JSON
      entries = JSON.parse(File.read(@log_file))

      # Reverse the entries (undo in reverse order)
      entries.reverse_each do |entry|
        begin
          FileUtils.mv(entry["from"], entry["to"])
          puts Color.green("  Restored: #{File.basename(entry["to"])}")
        rescue StandardError => e
          warn Color.red("  ERROR: #{File.basename(entry["to"])}, #{e.message}")
        end
      end

      # Remove the log file (the undo is complete)
      FileUtils.rm(@log_file)
      puts
      puts Color.green("Undo complete! #{entries.length} files restored.")
    end

    # stats: shows statistics about the folder.
    def stats
      # Get the scan results
      plan = scan

      # If folder is empty, say so
      if plan.empty?
        puts Color.green("Folder is already organized, nothing to show.")
        return
      end

      # Count files by category
      categories = plan.group_by { |f| f[:category] }

      # Calculate total size
      total_size = plan.sum { |f| f[:size] }

      puts Color.blue("Files in #{@directory}:")
      puts
      categories.each do |category, files|
        # Calculate category size
        category_size = files.sum { |f| f[:size] }
        puts Color.bold("  #{category}: #{files.length} files (#{format_size(category_size)})")
        files.each do |f|
          puts Color.dim("    - #{f[:filename]} (#{format_size(f[:size])})")
        end
      end
      puts
      puts Color.blue("Total: #{plan.length} files (#{format_size(total_size)})")
    end

    private

    # --- Private methods ---

    # scan_directory: scans a single directory (non-recursive).
    def scan_directory(dir)
      return [] unless File.directory?(dir)

      Dir.children(dir)
         .select { |f| File.file?(File.join(dir, f)) }
         .reject { |f| f.start_with?(".") }
         .map { |filename| build_file_entry(dir, filename) }
    end

    # scan_recursive: scans a directory and all its subdirectories.
    # Uses Dir.glob with ** to find all files recursively.
    def scan_recursive(dir)
      return [] unless File.directory?(dir)

      Dir.glob(File.join(dir, "**", "*"))
         .select { |path| File.file?(path) }
         .reject { |path| File.basename(path).start_with?(".") }
         .map do |path|
           # Get relative path from the base directory
           relative_path = path.sub("#{dir}/", "")
           filename = File.basename(path)
           subdirectory = File.dirname(relative_path)

           # Build the entry with the subdirectory info.
           # NOTE: must pass the file's actual containing directory
           # (File.dirname(path)), not the top-level `dir`, otherwise
           # nested files resolve to a path in the base directory that
           # doesn't exist (Errno::ENOENT) since they actually live in
           # a subfolder.
           entry = build_file_entry(File.dirname(path), filename)
           entry[:subcategory] = subdirectory == "." ? nil : subdirectory
           entry
         end
    end

    # build_file_entry: creates a hash describing one file.
    def build_file_entry(dir, filename)
      category = @config.extension_for(filename)
      full_path = File.join(dir, filename)

      {
        filename: filename,
        category: category || "Other",
        source: full_path,
        destination: File.join(dir, category || "Other", filename),
        size: File.size(full_path),
      }
    end

    # save_log: writes the move history to a file.
    # This uses JSON because it's human-readable and easy to parse.
    def save_log
      File.write(@log_file, JSON.pretty_generate(@moved_files))
    end

    # format_size: converts bytes to human-readable format.
    # This is a PRIVATE method, only used inside this class.
    #
    # Examples:
    #   format_size(0)          => "0 B"
    #   format_size(1024)       => "1.0 KB"
    #   format_size(1048576)    => "1.0 MB"
    #   format_size(1073741824) => "1.0 GB"
    #
    # How it works:
    # 1. Start with bytes
    # 2. Divide by 1024 to get KB
    # 3. If still too big, divide by 1024 again to get MB
    # 4. Keep going until the number is manageable
    # 5. Round to 1 decimal place and add the unit
    #
    def format_size(bytes)
      # Return "0 B" for empty files
      return "0 B" if bytes == 0

      # UNITS is an ARRAY of strings: ["B", "KB", "MB", "GB", "TB"]
      # Each element is the next larger unit of measurement.
      # We use .each_with_index to get both the unit and its position.
      #
      # .each_with_index is like .each, but also gives you a counter.
      # The counter starts at 0 and goes up by 1 for each element.
      #
      UNITS.each_with_index do |unit, index|
        # If bytes is less than 1024, we've found our unit.
        # Why 1024? Because 1 KB = 1024 bytes, 1 MB = 1024 KB, etc.
        #
        # The first time through: index = 0, unit = "B", bytes might be 512
        # If 512 < 1024, we return "512 B"
        #
        # If bytes is 2048, that's > 1024, so we divide by 1024 = 2.0
        # Next time: index = 1, unit = "KB", bytes might be 2.0
        # If 2.0 < 1024, we return "2.0 KB"
        #
        if bytes < 1024
          # .round(1) rounds to 1 decimal place
          # Example: 2.456789.round(1) => 2.5
          return "#{bytes.round(1)} #{unit}"
        end

        # Divide by 1024 to get the next larger unit
        # Example: 2048 / 1024 = 2.0
        bytes /= 1024.0
      end

      # If the file is bigger than all our units (huge file),
      # just show the last unit with the number.
      # This handles files bigger than 1 TB.
      "#{bytes.round(1)} #{UNITS.last}"
    end
  end
end
