#--
# Copyright 2006 by Chad Fowler, Rich Kilmer, Jim Weirich and others.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

class Gem::Ext::Builder

  def self.class_name
    name =~ /Ext::(.*)Builder/
    $1.downcase
  end

  def self.make(dest_path, results)
    unless File.exist? 'Makefile' then
      raise Gem::InstallError, "Makefile not found:\n\n#{results.join "\n"}"
    end

    mf = Gem.read_binary 'Makefile'
    mf = mf.gsub(/^RUBYARCHDIR\s*=\s*\$[^$]*/, "RUBYARCHDIR = #{dest_path}")
    mf = mf.gsub(/^RUBYLIBDIR\s*=\s*\$[^$]*/, "RUBYLIBDIR = #{dest_path}")
    mf = mf.gsub(/\s*\S+\.time$/, "")

    File.open('Makefile', 'wb') {|f| f.print mf}

    # try to find make program from Ruby configure arguments first
    RbConfig::CONFIG['configure_args'] =~ /with-make-prog\=(\w+)/
    make_program = $1 || ENV['MAKE'] || ENV['make']
    unless make_program then
      make_program = (/mswin/ =~ RUBY_PLATFORM) ? 'nmake' : 'make'
    end

    ['', ' install'].each do |target|
      cmd = "#{make_program}#{target}"
      run(cmd, results, "make#{target}")
    end
  end

  def self.redirector
    '2>&1'
  end

  def self.run(command, results, command_name = nil)
    verbose = Gem.configuration.really_verbose

    begin
      # TODO use Process.spawn when ruby 1.8 support is dropped.
      rubygems_gemdeps, ENV['RUBYGEMS_GEMDEPS'] = ENV['RUBYGEMS_GEMDEPS'], nil
      if verbose
        puts(command)
        system(command)
      else
        results << command
        results << `#{command} #{redirector}`
      end
    ensure
      ENV['RUBYGEMS_GEMDEPS'] = rubygems_gemdeps
    end

    unless $?.success? then
      results << "Building has failed. See above output for more information on the failure." if verbose
      raise Gem::InstallError, "#{command_name || class_name} failed:\n\n#{results.join "\n"}"
    end
  end

end

