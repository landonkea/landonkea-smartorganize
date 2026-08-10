# frozen_string_literal: true

module SmartOrganize
  # This module contains COLOR HELPERS for the terminal.
  #
  # WHY this exists:
  # Terminals can display colors! Colors make output easier to read.
  # Green = good, Red = bad, Yellow = warning, Blue = info.
  #
  # But NOT all terminals support colors. Some old terminals, or terminals
  # being recorded, might not show colors. So we need to CHECK if colors
  # are supported before using them.
  #
  # HOW it works:
  # We use ANSI escape codes. These are special characters that tell the
  # terminal "change to this color." For example, \e[32m means "green."
  # After we're done with colored text, we use \e[0m to "reset" back to
  # normal (no color).
  #
  # The \e is an "escape character." It's not the letter 'e', it's a
  # special non-printable character (ASCII code 27, or 0x1B in hex).
  # The terminal recognizes this character as the start of an escape sequence.
  #
  # The numbers after \e[ are called "SGR codes" (Select Graphic Rendition):
  #   0  = reset (stop all formatting)
  #   1  = bold (thicker text)
  #   31 = red text
  #   32 = green text
  #   33 = yellow text
  #   34 = blue text
  #   37 = white text
  #   90 = dark gray text (for less important info)
  #
  module Color
    # These are METHODS that wrap text in color codes.
    # They're defined as module methods (using `self.method_name`)
    # so we can call them directly: SmartOrganize::Color.red("text")
    # They're NOT instance methods, so you don't need to create an object.

    def self.red(text)
      colorize(text, 31)
    end

    def self.green(text)
      colorize(text, 32)
    end

    def self.yellow(text)
      colorize(text, 33)
    end

    def self.blue(text)
      colorize(text, 34)
    end

    def self.bold(text)
      colorize(text, 1)
    end

    def self.dim(text)
      colorize(text, 90)
    end

    private

    # The `private` keyword means this method CANNOT be called from outside
    # this module. You can only use it inside the Color module's own methods.
    # WHY? Because `colorize` is an IMPLEMENTATION DETAIL. Users of Color
    # should use `.red("text")`, not `.colorize("text", 31)` directly.
    # This is the "private methods" concept, hide the plumbing.

    # `colorize` is the CORE METHOD that all the color methods use.
    # Instead of repeating the escape code logic in every method,
    # we put it here once and call it from the others.
    # This is the DRY principle: Don't Repeat Yourself.
    #
    # Parameters:
    #   text, the string to colorize
    #   code, the ANSI color code number (31 for red, 32 for green, etc.)
    #
    # Returns: a string wrapped in ANSI escape codes, like "\e[31mHello\e[0m"
    #
    def self.colorize(text, code)
      # Check if the terminal supports colors.
      # STDOUT.tty? returns true if output goes to a real terminal,
      # false if output is being piped to a file or another program.
      #
      # WHY check? If you run `smartorganize scan > output.txt`,
      # the output goes to a file, not a terminal. The file would contain
      # garbage characters like "[32m" instead of showing colors.
      # So we skip the color codes when output isn't a terminal.
      #
      # ENV["NO_COLOR"] is a standard environment variable. If set,
      # we should NOT use colors (for accessibility or compatibility).
      #
      return text unless stdout_supports_color?

      "\e[#{code}m#{text}\e[0m"
    end

    def self.stdout_supports_color?
      # Check both conditions: must be a terminal AND no NO_COLOR env var
      $stdout.tty? && !ENV["NO_COLOR"]
    end
  end
end
