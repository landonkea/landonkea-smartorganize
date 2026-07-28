# lib/smartorganize/organizer.rb
#
# This is the CORE LOGIC — the engine that actually organizes files.
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
    # --- Initialize ---
    # Takes a directory path and a Config object.
    def initialize(directory, config)
      # File.expand_path converts relative paths to absolute paths.
      # "~/Downloads" becomes "/Users/landonkea/Downloads"
      @directory = File.expand_path(directory)
      @config = config

      # @log_file is where we record every move we make.
      # This is how "undo" works — we read the log backwards.
      @log_file = File.join(@directory, ".smartorganize.log")

      # @moved_files tracks what we move in this session.
      # It starts as an empty array — we'll push each move into it.
      @moved_files = []
    end

    # --- Public methods ---

    # scan: looks at all files and shows what WOULD be moved.
    # This is the "dry run" — nothing actually changes on disk.
    #
    # Returns an array of hashes, each describing one file's fate.
    def scan
      # Dir.children returns the names of everything in @directory.
      # .select filters to only files (not folders).
      # .reject filters out hidden files (names starting with ".").
      files = Dir.children(@directory)
                 .select { |f| File.file?(File.join(@directory, f)) }
                 .reject { |f| f.start_with?(".") }

      # .map transforms each filename into a hash describing it.
      # This is like a "report" — we're not moving anything yet.
      files.map do |filename|
        category = @config.extension_for(filename)

        {
          filename: filename,
          category: category || "Other",
          source: File.join(@directory, filename),
          # File.join is better than string concatenation because it
          # handles the "/" separator correctly on all operating systems.
          destination: File.join(@directory, category || "Other", filename),
        }
      end
    end

    # organize: actually moves files into categorized subfolders.
    # This is the "real" action — files WILL be moved on disk.
    #
    # Returns a summary of what was done.
    def organize
      # Get the scan results first
      plan = scan

      # If nothing to organize, say so and return early
      if plan.empty?
        puts "Nothing to organize — folder is already clean!"
        return { moved: 0, categories: {} }
      end

      # Print what we're about to do
      puts "Organizing #{plan.length} files..."
      puts

      # Track statistics for the summary
      stats = { moved: 0, categories: {} }

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

          # Print what we did
          puts "  #{file[:filename]} -> #{file[:category]}/"

        rescue Errno::EEXIST => e
          # This error means a file with the same name already exists
          # in the destination. We skip it rather than overwriting.
          warn "  SKIP: #{file[:filename]} (already exists in #{file[:category]}/)"
        rescue StandardError => e
          # Any other error — print the message and continue
          warn "  ERROR: #{file[:filename]} — #{e.message}"
        end
      end

      # Save the log file so "undo" can work later
      save_log

      # Print summary
      puts
      puts "Done! Moved #{stats[:moved]} files."
      stats[:categories].each do |category, count|
        puts "  #{category}: #{count} files"
      end

      stats
    end

    # undo: reverses the last organize operation.
    # It reads the log file and moves everything back.
    def undo
      # Check if there's a log file to undo
      unless File.exist?(@log_file)
        puts "Nothing to undo — no log file found."
        return
      end

      # Read the log file and parse it as JSON
      entries = JSON.parse(File.read(@log_file))

      # Reverse the entries (undo in reverse order)
      entries.reverse_each do |entry|
        begin
          FileUtils.mv(entry["from"], entry["to"])
          puts "  Restored: #{File.basename(entry["to"])}"
        rescue StandardError => e
          warn "  ERROR: #{File.basename(entry["to"])} — #{e.message}"
        end
      end

      # Remove the log file (the undo is complete)
      FileUtils.rm(@log_file)
      puts
      puts "Undo complete! #{entries.length} files restored."
    end

    # stats: shows statistics about the folder.
    def stats
      # Get the scan results
      plan = scan

      # If folder is empty, say so
      if plan.empty?
        puts "Folder is already organized — nothing to show."
        return
      end

      # Count files by category
      categories = plan.group_by { |f| f[:category] }

      puts "Files in #{@directory}:"
      puts
      categories.each do |category, files|
        puts "  #{category}: #{files.length} files"
        files.each { |f| puts "    - #{f[:filename]}" }
      end
      puts
      puts "Total: #{plan.length} files to organize"
    end

    private

    # --- Private methods ---

    # save_log: writes the move history to a file.
    # This uses JSON because it's human-readable and easy to parse.
    def save_log
      File.write(@log_file, JSON.pretty_generate(@moved_files))
    end
  end
end
