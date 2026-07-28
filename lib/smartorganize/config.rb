# lib/smartorganize/config.rb
#
# This file handles CONFIGURATION — the user's settings.
# It reads a YAML file (like .smartorganize.yml) and turns it into
# Ruby data structures we can use.
#
# YAML is a human-readable file format. For example:
#   categories:
#     Documents:
#       - pdf, doc, txt
#     Images:
#       - jpg, png, gif
#
# In Ruby, that becomes a nested hash:
#   { "categories" => { "Documents" => ["pdf", "doc", "txt"], ... } }

# --- Require the YAML library ---
# "yaml" is a built-in Ruby library (you don't need to install it).
# It knows how to read YAML files and convert them to Ruby objects.
require "yaml"

module SmartOrganize
  # --- Config class ---
  # This class is responsible for:
  # 1. Finding the config file
  # 2. Reading it
  # 3. Providing default values if the file doesn't exist
  class Config
    # --- Default categories ---
    # If the user hasn't created a config file, we use these defaults.
    # This is a HASH where:
    #   - Each KEY is a category name (like "Documents")
    #   - Each VALUE is an array of file extensions (like ["pdf", "doc", "txt"])
    #
    # The "freeze" method makes the hash IMMUTABLE — you can't change it
    # at runtime. This prevents accidental modification.
    DEFAULT_CATEGORIES = {
      "Documents" => %w[pdf doc docx txt md rtf odt pages],
      "Images"    => %w[jpg jpeg png gif svg webp bmp ico tiff],
      "Videos"    => %w[mp4 mov avi mkv webm flv wmv m4v],
      "Audio"     => %w[mp3 wav flac aac ogg wma m4a aiff],
      "Archives"  => %w[zip tar gz rar 7z bz2 xz dmg iso],
      "Code"      => %w[rb py js ts go java cs cpp c h php swift kt],
      "Data"      => %w[json csv xml yaml yml sql db sqlite],
      "Executables" => %w[dmg exe msi deb rpm appimage],
    }.freeze

    # --- Initialize ---
    # The "initialize" method runs when you do Config.new.
    # It takes an optional path to a config file.
    #
    # The "?:" is called the "ternary operator" — it's a shorthand for if/else:
    #   path ? path : default_path
    # means "if path was given, use it; otherwise use default_path"
    def initialize(path = nil)
      # @path is an INSTANCE VARIABLE — it belongs to this specific
      # Config object. Other objects can't see it unless we give them access.
      @path = path || default_config_path

      # @categories will hold the parsed categories from the config file.
      # We start with the defaults, then override with user settings if they exist.
      @categories = DEFAULT_CATEGORIES.dup

      # Load the user's config file if it exists
      load_config if File.exist?(@path)
    end

    # --- Public methods ---

    # categories: returns the current categories hash.
    # The "attr_reader" macro automatically creates this method for us:
    #   def categories; @categories; end
    attr_reader :categories

    # extension_for(filename): takes a filename like "report.pdf"
    # and returns the category it belongs to, like "Documents".
    #
    # The "find" method iterates through the hash and returns the FIRST
    # match. It uses "any?" to check if the extension is in the list.
    def extension_for(filename)
      # File.extname("report.pdf") returns ".pdf" (with the dot)
      # .delete(".") removes the dot, giving us just "pdf"
      ext = File.extname(filename).delete(".").downcase

      # .find returns the first key (category name) where the block is true
      @categories.find do |_category, extensions|
        extensions.include?(ext)
      end&.first  # &.first means "if find returned something, get its first element"
    end

    # to_yaml: converts the current config back to YAML format.
    # This is useful for saving the config to a file.
    def to_yaml
      YAML.dump({ "categories" => @categories })
    end

    private

    # --- Private methods (can only be called from inside this class) ---

    # default_config_path: returns the default location for the config file.
    # Dir.home returns the user's home directory (like "/Users/landonkea").
    def default_config_path
      File.join(Dir.home, ".smartorganize.yml")
    end

    # load_config: reads the YAML file and merges it with defaults.
    def load_config
      # YAML.load_file reads a YAML file and converts it to a Ruby hash.
      # The "safe_load" version is safer (doesn't execute arbitrary Ruby).
      user_config = YAML.safe_load(File.read(@path))

      # If the file has a "categories" section, merge it with defaults.
      # .merge means "combine the two hashes — user settings override defaults"
      if user_config.is_a?(Hash) && user_config["categories"]
        @categories = DEFAULT_CATEGORIES.merge(user_config["categories"])
      end
    rescue YAML::Error => e
      # If the YAML file is malformed, warn the user but don't crash.
      # We fall back to defaults.
      warn "Warning: Could not parse config file: #{e.message}"
      warn "Using default categories instead."
    end
  end
end
