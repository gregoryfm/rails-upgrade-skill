# frozen_string_literal: true

# Lists the locked gems whose own gemspec excludes the next Rails version:
# the gems that must be bumped or replaced before the bump can resolve. It
# reads only the lockfile, so it needs no network, no next_rails and no
# `bundle install`, and it answers the same way every run.
#
# Usage, from the app root:
#
#   ruby <skill>/detection-scripts/gem_limits.rb                        # hop from Gemfile.lock
#   ruby <skill>/detection-scripts/gem_limits.rb --target 4.2
#   ruby <skill>/detection-scripts/gem_limits.rb --lockfile Gemfile.next.lock
#   ruby <skill>/detection-scripts/gem_limits.rb --self-test
#
# Without --target, the target is the hop after the lockfile's Rails version,
# taken from version-guides/ the same way scan_patterns.rb takes it.
#
# Runs with the app's own Ruby, so it stays Ruby 2.1 compatible: stdlib only,
# no `&.`, no `<<~`, no `String#match?`, no `Array#sum`, no `filter_map`.
#
# What counts as capped, and why:
#
# 1. Only a gem's dependencies on the Rails framework gems are checked. A
#    limit on any other gem, or one only a README states, is invisible here.
# 2. A limit allows the target when any X.Y.Z patch of it satisfies the
#    requirement: `>= 4.1.2` allows 4.1, `~> 4.0.0` does not.
# 3. The framework gems themselves move with `rails` and are never listed.
# 4. A gem only the framework gems pull in (not in DEPENDENCIES) is skipped:
#    the next `rails` resolves its own version of it, or drops it (3.2's
#    activeresource).
# 5. A gem pulled in by another gem names its parents and their requirement
#    on it, since bumping the parent is often how it moves.
# 6. Platform variants of one gem (nokogiri 1.6.8 and 1.6.8-x86_64-linux)
#    are one gem: their dependencies are merged, so a limit only one variant
#    declares still counts, and the plain version is the one shown.

require "optparse"
require "rubygems"
require_relative "hop"

FRAMEWORK_GEMS = %w[
  rails railties actionpack actionview activerecord activemodel activesupport
  actionmailer activejob actioncable activestorage actiontext actionmailbox
].freeze
SPEC_SECTIONS = %w[GEM GIT PATH].freeze

# { :specs => { name => { :version, :source, :deps => { name => [req, ...] } } },
#   :direct => [names] }
def parse_lockfile(text)
  specs = {}
  direct = []
  section = nil
  source = nil
  current = nil
  text.each_line do |raw|
    line = raw.chomp
    if line =~ /\A(\S.*)\z/
      section = $1.strip
      source = section.downcase
      current = nil
      next
    end
    if section == "DEPENDENCIES"
      direct << $1 if line =~ /\A  ([^\s!(]+)/
    elsif SPEC_SECTIONS.include?(section)
      if line =~ /\A    (\S+) \(([^)]+)\)\z/
        version = $2
        current = (specs[$1] ||= { :version => version, :source => source, :deps => {} })
        current[:version] = version if current[:version].include?("-") && !version.include?("-")
      elsif current && line =~ /\A      (\S+)(?: \(([^)]+)\))?\z/
        # Platform variants each list their dependencies: keep every distinct
        # requirement, so the strictest one is checked whatever the order.
        reqs = (current[:deps][$1] ||= [])
        req = $2 || ">= 0"
        reqs << req unless reqs.include?(req)
      end
    end
  end
  { :specs => specs, :direct => direct }
end

def allows_minor?(requirement, minor)
  req = Gem::Requirement.new(*requirement.split(/,\s*/))
  (0..99).any? { |patch| req.satisfied_by?(Gem::Version.new("#{minor}.#{patch}")) }
end

# [{ :name, :version, :source, :limits => ["actionpack >= 3.1, < 4.1"], :direct, :parents }]
def capped_gems(lock, target)
  specs = lock[:specs]
  parents = Hash.new { |h, k| h[k] = [] }
  specs.each { |name, s| s[:deps].each { |dep, reqs| parents[dep] << [name, reqs.join("; ")] } }

  specs.keys.sort.map do |name|
    next if FRAMEWORK_GEMS.include?(name)
    spec = specs[name]
    limits = []
    spec[:deps].each do |dep, reqs|
      next unless FRAMEWORK_GEMS.include?(dep)
      reqs.each { |req| limits << [dep, req] unless allows_minor?(req, target) }
    end
    next if limits.empty?
    direct = lock[:direct].include?(name)
    gem_parents = parents[name].reject { |parent, _| FRAMEWORK_GEMS.include?(parent) }
    next if !direct && gem_parents.empty?
    {
      :name => name, :version => spec[:version], :source => spec[:source], :direct => direct,
      :limits => limits.map { |dep, req| "#{dep} #{req}" },
      :parents => gem_parents.map { |parent, req| req == ">= 0" ? parent : "#{parent} (#{req})" }
    }
  end.compact
end

def md_cell(s)
  s.to_s.gsub("|", "\\|")
end

def render(meta, capped)
  out = []
  out << "# Gem limits: Rails #{meta[:from]} -> #{meta[:to]}"
  out << ""
  out << "- Lockfile: `#{meta[:lockfile]}` (#{meta[:locked_rails]})"
  out << "- Hop source: #{meta[:hop_source]}"
  out << ""
  if capped.empty?
    out << "No locked gem declares a Rails framework limit that excludes #{meta[:to]}."
  else
    out << "## Capped below #{meta[:to]} (#{capped.length})"
    out << ""
    out << "Each gem's own gemspec excludes Rails #{meta[:to]}, so the bump cannot resolve until it is bumped " \
           "to a release that allows #{meta[:to]}, replaced, or dropped. A newer release may lift the limit; " \
           "this lockfile cannot tell."
    out << ""
    out << "| Gem | Locked | Source | Declared limit | In Gemfile | Pulled in by |"
    out << "|-----|--------|--------|----------------|------------|--------------|"
    capped.each do |g|
      out << "| #{md_cell(g[:name])} | #{md_cell(g[:version])} | #{g[:source]} | #{md_cell(g[:limits].join('; '))} | " \
             "#{g[:direct] ? 'yes' : 'no'} | #{md_cell(g[:parents].join(', '))} |"
    end
  end
  out << ""
  out << "Not checked: limits on non-Rails gems, limits stated only in a README, and runtime breakage."
  out.join("\n") + "\n"
end

def self_test
  failures = []
  check = lambda { |desc, ok| failures << desc unless ok }
  lock = parse_lockfile(<<-LOCK)
GIT
  remote: https://github.com/example/forked_gem.git
  revision: abc123
  specs:
    forked_gem (2.0.0)
      activerecord (>= 3.2, < 4.1)

GEM
  remote: https://rubygems.org/
  specs:
    actionpack (4.0.13)
      activesupport (= 4.0.13)
    activesupport (4.0.13)
    devise (3.5.10)
      railties (>= 3.2.6, < 5)
      responders
    haml-rails (0.4)
      actionpack (>= 3.1, < 4.1)
      railties (>= 3.1, < 4.1)
    inherited_resources (1.5.1)
      actionpack (>= 3.2, < 4.2)
      responders (~> 1.0)
    nokogiri (1.6.8-x86_64-linux)
    nokogiri (1.6.8)
      mini_portile2 (~> 2.1.0)
    variant_capped (1.0-java)
    variant_capped (1.0)
      railties (>= 4.0, < 6.1)
    variant_later (1.0-x86_64-linux)
      railties (>= 4.0)
    variant_later (1.0)
      railties (>= 4.0, < 5)
    rails (4.0.13)
      actionpack (= 4.0.13)
      sprockets-rails (~> 2.0)
    railties (4.0.13)
      actionpack (= 4.0.13)
    responders (1.1.2)
      railties (>= 3.2, < 4.2)
    patch_floor (1.0)
      activerecord (>= 4.1.2)
    simple_form (3.0.0)
      actionpack (~> 4.0.0)
    sprockets-rails (2.0.1)
      actionpack (>= 3.0, < 4.1)

PLATFORMS
  ruby

DEPENDENCIES
  devise
  forked_gem!
  haml-rails
  inherited_resources (~> 1.5)
  nokogiri
  patch_floor
  rails (= 4.0.13)
  simple_form
  variant_capped
  variant_later
LOCK
  check.call("parses the direct gems, ! and requirements stripped", lock[:direct].include?("forked_gem") && lock[:direct].include?("inherited_resources"))
  check.call("shows the plain version of a gem with platform variants", lock[:specs]["nokogiri"][:version] == "1.6.8")
  check.call("merges the platform variants' dependencies", lock[:specs]["nokogiri"][:deps].key?("mini_portile2"))
  check.call("a bare dependency allows any version", lock[:specs]["devise"][:deps]["responders"] == [">= 0"])

  names41 = capped_gems(lock, "4.1").map { |g| g[:name] }
  check.call("4.1 caps haml-rails, simple_form, forked_gem (got #{names41.inspect})", names41 == %w[forked_gem haml-rails simple_form])
  check.call("a gem only rails pulls in is skipped (sprockets-rails)", !names41.include?("sprockets-rails"))
  check.call("a patch floor allows the minor (patch_floor >= 4.1.2)", !names41.include?("patch_floor"))
  forked = capped_gems(lock, "4.1").find { |g| g[:name] == "forked_gem" }
  check.call("a git gem keeps its source", forked && forked[:source] == "git")

  capped42 = capped_gems(lock, "4.2")
  responders = capped42.find { |g| g[:name] == "responders" }
  check.call("4.2 caps inherited_resources and responders (got #{capped42.map { |g| g[:name] }.inspect})",
             capped42.map { |g| g[:name] }.include?("inherited_resources") && responders)
  check.call("a transitive gem names its parents and their requirement (got #{responders && responders[:parents].inspect})",
             responders && responders[:parents] == ["devise", "inherited_resources (~> 1.0)"] && !responders[:direct])
  check.call("the framework gems are never listed", capped_gems(lock, "5.0").none? { |g| FRAMEWORK_GEMS.include?(g[:name]) })
  check.call("a limit only one platform variant declares counts (variant_capped)",
             capped_gems(lock, "6.1").any? { |g| g[:name] == "variant_capped" })
  check.call("a stricter limit on a later platform variant counts (variant_later)",
             capped_gems(lock, "5.0").any? { |g| g[:name] == "variant_later" })
  failures.concat(Hop.self_test_failures)

  if failures.empty?
    puts "gem_limits: self-test OK"
    exit 0
  end
  failures.each { |f| warn "FAIL: #{f}" }
  exit 1
end

if $PROGRAM_NAME == __FILE__
  opts = { :root => ".", :lockfile => "Gemfile.lock" }
  OptionParser.new do |o|
    o.banner = "Usage: ruby gem_limits.rb [--target X.Y] [--root DIR] [--lockfile FILE]"
    o.on("--target VERSION", "target Rails version, e.g. 4.1 (default: next hop after the lockfile's rails)") { |v| opts[:target] = v }
    o.on("--root DIR", "app root (default: .)") { |v| opts[:root] = v }
    o.on("--lockfile FILE", "lockfile, relative to --root (default: Gemfile.lock; Gemfile.next.lock for the next boot)") { |v| opts[:lockfile] = v }
    o.on("--self-test", "run built-in assertions and exit") { opts[:self_test] = true }
  end.parse!

  self_test if opts[:self_test]

  root = File.expand_path(opts[:root])
  lockfile = File.expand_path(opts[:lockfile], root)
  abort("gem_limits: #{lockfile} not found") unless File.file?(lockfile)
  text = File.read(lockfile, :encoding => "UTF-8")
  hop = Hop.resolve(text, opts[:target], File.basename(lockfile))
  abort("gem_limits: #{hop[:error]}") if hop[:error]
  if hop[:behind]
    abort("gem_limits: #{File.basename(lockfile)} is already on Rails #{hop[:current]}, so it resolves for #{hop[:to]}; " \
          "pass a --target ahead of it, or --lockfile for the other boot")
  end

  meta = {
    :from => hop[:from], :to => hop[:to], :lockfile => lockfile.sub("#{root}/", ""),
    :locked_rails => hop[:locked] || "none", :hop_source => hop[:source]
  }
  print render(meta, capped_gems(parse_lockfile(text), hop[:to]))
end
