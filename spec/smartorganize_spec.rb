# spec/smartorganize_spec.rb
#
# This is the TEST FILE — it verifies that our code works correctly.
# Tests are written BEFORE bugs appear — they catch problems early.
#
# Minitest is Ruby's built-in test framework. It's simple and fast.
# We use "assert" methods to check that our code does what we expect.

# --- Require the test framework and our code ---
require "minitest/autorun"
require "smartorganize"

# --- Test class ---
# The class name must end with "Test" — Minitest looks for this.
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
end
