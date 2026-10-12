# frozen_string_literal: true

require "rubygems"

# Which hop an app is on, shared by scan_patterns.rb and gem_limits.rb so the
# two scripts always name the same hop for the same lockfile. Loaded with
# require_relative and run with the app's Ruby: stdlib only, Ruby 2.1
# compatible.
module Hop
  GUIDES_DIR = File.expand_path("../version-guides", __dir__)

  # The framework gem and version a lockfile pins (["rails", "4.0.13"]), or
  # nil. `rails` first; an app that depends on railties directly (API-only,
  # slimmed) has no `rails` spec, and railties moves in lockstep with it.
  def self.locked_spec(text)
    %w[rails railties].each do |name|
      v = text.to_s[/^    #{name} \(([^)\s]+)\)/, 1]
      return [name, v] if v
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

  # The version guide whose hop ends at `target`, or nil.
  def self.guide_for(target)
    Dir[File.join(GUIDES_DIR, "upgrade-*-to-#{target}.md")].first
  end

  # The version a hop to `target` starts from (7.0 -> "6.1"), or nil.
  def self.from_for(target)
    g = guide_for(target)
    g ? File.basename(g)[/\Aupgrade-(\d+\.\d+)-to-/, 1] : nil
  end

  # "41", "4.1" and "4.1.2" -> "4.1"; anything else ("6", "v6.1", "6.x") -> nil,
  # so a caller can refuse it instead of checking the wrong versions.
  def self.normalize_target(t)
    t = t.to_s.strip
    t = "#{t[0..-2]}.#{t[-1]}" if t =~ /\A\d{2,3}\z/
    t =~ /\A(\d+\.\d+)(?:\.\d+)*\z/ ? $1 : nil
  end

  # The one place that decides the hop. Returns a Hash:
  #   :from, :to       the hop (from the version guides)
  #   :current         the lockfile's Rails minor, or nil
  #   :locked          "railties 6.0.6" style label, or nil
  #   :source          one line saying where the hop came from
  #   :behind          true when --target is not ahead of the lockfile
  #   :error           set instead of the above when there is no such hop
  def self.resolve(lock_text, target_arg, lock_name = "Gemfile.lock")
    name, version = locked_spec(lock_text)
    current = minor(version)
    locked = version ? "#{name} #{version}" : nil
    if target_arg
      target = normalize_target(target_arg)
      return { :error => "--target #{target_arg.inspect} is not a Rails version like 4.1" } unless target
      from = from_for(target)
      return { :error => "no version guide ends at Rails #{target}, so there is no #{target} hop" } unless from
      behind = current && Gem::Version.new(target) <= Gem::Version.new(current)
      { :from => from, :to => target, :current => current, :locked => locked, :source => "--target",
        :behind => behind ? true : false }
    else
      return { :error => "no rails or railties in #{lock_name}; pass --target X.Y" } unless current
      target = next_after(current)
      unless target
        return { :error => "no version guide starts at Rails #{current}, so the next hop is unknown. Pass --target X.Y" }
      end
      { :from => current, :to => target, :current => current, :locked => locked, :behind => false,
        :source => "#{lock_name} pins #{locked}; next hop is #{target}" }
    end
  end

  # Assertions shared by both scripts' --self-test.
  def self.self_test_failures
    failures = []
    check = lambda { |desc, ok| failures << "hop: #{desc}" unless ok }
    check.call("normalizes 41 and 4.1.2", normalize_target("41") == "4.1" && normalize_target("4.1.2") == "4.1")
    check.call("refuses a target that is not X.Y", %w[6 v6.1 6.x].all? { |t| normalize_target(t).nil? })
    rail = "GEM\n  specs:\n    railties (6.0.6)\n"
    r = resolve(rail, nil)
    check.call("falls back to railties and says so (got #{r.inspect})",
               r[:to] == "6.1" && r[:source] == "Gemfile.lock pins railties 6.0.6; next hop is 6.1")
    check.call("the 6.0 hop is 6.1 per the guides, not the next patterns file", next_after("6.0") == "6.1")
    check.call("no guide starts at 3.1", next_after("3.1").nil?)
    check.call("--target names the guide's start, not the lockfile's", resolve(rail, "7.0")[:from] == "6.1")
    check.call("--target with no guide is an error", resolve(rail, "9.9")[:error])
    check.call("--target not ahead of the lockfile is flagged", resolve(rail, "6.0")[:behind] && !resolve(rail, "6.1")[:behind])
    check.call("no lockfile and no target is an error", resolve(nil, nil)[:error])
    failures
  end
end
