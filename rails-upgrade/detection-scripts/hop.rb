# frozen_string_literal: true

# Which hop an app is on, shared by scan_patterns.rb and gem_limits.rb so the
# two scripts always name the same hop for the same lockfile. Loaded with
# require_relative and run with the app's Ruby: stdlib only, Ruby 2.1
# compatible.
module Hop
  GUIDES_DIR = File.expand_path("../version-guides", __dir__)

  # The framework version a lockfile pins ("4.0.13"), or nil. `rails` first;
  # an app that depends on railties directly (API-only, slimmed) has no
  # `rails` spec, and railties moves in lockstep with it.
  def self.locked_version(text)
    %w[rails railties].each do |name|
      v = text[/^    #{name} \(([^)\s]+)\)/, 1]
      return v if v
    end
    nil
  end

  # "4.0.13" -> "4.0"
  def self.minor(version)
    version ? version[/\A\d+\.\d+/] : nil
  end

  # The hop after `current` according to the version guides (6.0 -> 6.1), or
  # nil when no guide starts at `current`. The guides, not the patterns files,
  # define the hops: 6.1 has a guide and no patterns file.
  def self.next_after(current)
    g = Dir[File.join(GUIDES_DIR, "upgrade-#{current}-to-*.md")].first
    g ? File.basename(g)[/-to-(\d+\.\d+)\.md\z/, 1] : nil
  end

  # "41", "4.1" and "4.1.2" -> "4.1"; anything else ("6", "v6.1", "6.x") -> nil,
  # so a caller can refuse it instead of checking the wrong versions.
  def self.normalize_target(t)
    t = t.to_s.strip
    t = "#{t[0..-2]}.#{t[-1]}" if t =~ /\A\d{2,3}\z/
    t =~ /\A(\d+\.\d+)(?:\.\d+)*\z/ ? $1 : nil
  end
end
