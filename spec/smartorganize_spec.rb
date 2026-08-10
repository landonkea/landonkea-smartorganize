# spec/smartorganize_spec.rb
#
# This is the TEST FILE, it verifies that our code works correctly.
# Tests are written BEFORE bugs appear, they catch problems early.
#
# Minitest is Ruby's built-in test framework. It's simple and fast.
# We use "assert" methods to check that our code does what we expect.

# --- Require the test framework and our code ---
require "minitest/autorun"
require "stringio"
require "smartorganize"

# --- Test class ---
# The class name must end with "Test", Minitest looks for this.
# It inherits from Minitest::Test, which gives us all the assert methods.
class SmartOrganizeTest < Minitest::Test
  # --- setup: runs before EACH test method ---
  # This creates a temporary directory with test files.
  # We use Dir.mktmpdir because it auto-deletes when we're done.
  def setup
    # Dir.mktmpdir creates a temporary folder like "/tmp/smartorganize12345"
    @test_dir = Dir.mktmpdir("smartorganize-test")

    # Create test files of different types
    File.write(File.join(@test_dir, "report.pdf"), "fake pdf")
    File.write(File.join(@test_dir, "photo.jpg"), "fake jpg")
    File.write(File.join(@test_dir, "script.rb"), "fake ruby")
    File.write(File.join(@test_dir, "data.json"), "{}")
    File.write(File.join(@test_dir, "notes.txt"), "hello")
  end

  # --- teardown: runs after EACH test method ---
  # This cleans up the temporary directory.
  # FileUtils.rm_rf removes a folder and everything inside it.
  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  # --- Test: Config loads correctly ---
  def test_config_has_default_categories
    config = SmartOrganize::Config.new
    # assert_includes checks that the array includes the expected value
    assert_includes config.categories.keys, "Documents"
    assert_includes config.categories.keys, "Images"
    assert_includes config.categories.keys, "Code"
  end

  # --- Test: Config identifies file extensions ---
  def test_config_extension_for
    config = SmartOrganize::Config.new
    # assert_equal checks that two values are the same
    assert_equal "Documents", config.extension_for("report.pdf")
    assert_equal "Images", config.extension_for("photo.jpg")
    assert_equal "Code", config.extension_for("script.rb")
    # assert_nil checks that a value is nil (no category found)
    assert_nil config.extension_for("unknown.xyz")
  end

  # --- Test: Organizer scans files correctly ---
  def test_organizer_scan
    config = SmartOrganize::Config.new
    organizer = SmartOrganize::Organizer.new(@test_dir, config)
    results = organizer.scan

    # assert_equal checks the count matches
    assert_equal 5, results.length
    # assert_kind_of checks the type of the result
    assert_kind_of Array, results
    # assert_includes checks that specific files are in the results
    assert results.any? { |f| f[:filename] == "report.pdf" }
    assert results.any? { |f| f[:filename] == "photo.jpg" }
  end

  # --- Test: Organizer actually moves files ---
  def test_organize_moves_files
    config = SmartOrganize::Config.new
    organizer = SmartOrganize::Organizer.new(@test_dir, config)
    organizer.organize

    # After organizing, files should be in subfolders
    assert File.exist?(File.join(@test_dir, "Documents", "report.pdf"))
    assert File.exist?(File.join(@test_dir, "Images", "photo.jpg"))
    assert File.exist?(File.join(@test_dir, "Code", "script.rb"))
  end

  # --- Test: Undo restores files ---
  def test_undo_restores_files
    config = SmartOrganize::Config.new
    organizer = SmartOrganize::Organizer.new(@test_dir, config)
    organizer.organize
    organizer.undo

    # After undo, files should be back in the original location
    assert File.exist?(File.join(@test_dir, "report.pdf"))
    assert File.exist?(File.join(@test_dir, "photo.jpg"))
  end

  # --- Test: CLI "stats" command respects --recursive ---
  # This guards against the CLI silently dropping the --recursive flag
  # when building the Organizer for cmd_stats (it previously omitted
  # `recursive: recursive?`, so files in subfolders were never counted).
  def test_cli_stats_respects_recursive_flag
    subdir = File.join(@test_dir, "subfolder")
    FileUtils.mkdir_p(subdir)
    File.write(File.join(subdir, "nested.pdf"), "fake nested pdf")

    output = capture_stdout do
      SmartOrganize::CLI.new(["stats", @test_dir, "--recursive"]).run
    end

    assert_includes output, "nested.pdf"
    # Total should include all 6 files (5 top-level + 1 nested)
    assert_includes output, "Total: 6 files"
  end

  # --- Test: CLI "stats" without --recursive stays top-level only ---
  def test_cli_stats_without_recursive_flag_ignores_subfolders
    subdir = File.join(@test_dir, "subfolder")
    FileUtils.mkdir_p(subdir)
    File.write(File.join(subdir, "nested.pdf"), "fake nested pdf")

    output = capture_stdout do
      SmartOrganize::CLI.new(["stats", @test_dir]).run
    end

    refute_includes output, "nested.pdf"
    assert_includes output, "Total: 5 files"
  end

  # --- Test: CLI "undo" command accepts --recursive consistently ---
  # undo itself only replays the log file, but it must build the
  # Organizer the same way scan/organize do (passing recursive:)
  # instead of silently dropping the flag.
  def test_cli_undo_respects_recursive_flag
    SmartOrganize::CLI.new(["organize", @test_dir, "--force"]).run

    output = capture_stdout do
      SmartOrganize::CLI.new(["undo", @test_dir, "--recursive"]).run
    end

    assert_includes output, "Undo complete!"
    assert File.exist?(File.join(@test_dir, "report.pdf"))
    assert File.exist?(File.join(@test_dir, "photo.jpg"))
  end

  private

  # capture_stdout: redirects $stdout to a StringIO for the duration
  # of the block, then returns everything that was printed.
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
