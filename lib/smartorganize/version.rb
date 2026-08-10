# lib/smartorganize/version.rb
#
# This file holds ONLY the version number.
# Separating it into its own file means other files can check the version
# without loading the entire program. It's a small thing, but it's a
# professional convention, every real Ruby gem does this.
module SmartOrganize
  # VERSION: the current version of this tool.
  # We follow "semantic versioning" (semver):
  #   MAJOR.MINOR.PATCH
  #   - MAJOR: breaking changes (things stop working)
  #   - MINOR: new features (things still work)
  #   - PATCH: bug fixes (things work better)
  # Right now we're at 0.1.0, pre-release, early development.
  VERSION = "0.1.0"
end
