require 'bundler'
require 'rspec/core/rake_task'

require 'kuby'

task :build do
  require 'curdle'
  require 'tmpdir'
  require 'fileutils'

  Dir.mktmpdir do |build_dir|
    spec = Bundler.load_gemspec('kuby-core.gemspec')

    spec.files.each do |source_path|
      next if File.directory?(source_path)

      dest_path = File.join(build_dir, source_path)
      FileUtils.mkdir_p(File.dirname(dest_path))

      if File.extname(source_path) == '.rb'
        File.write(dest_path, Curdle.process(File.read(source_path)))
      else
        FileUtils.cp(source_path, dest_path)
      end
    end

    system("gem build --silent -C #{build_dir}")
    artifact = Dir.glob(File.join(build_dir, 'kuby-core*.gem')).first

    FileUtils.mkdir_p('pkg')
    artifact_dest = File.join('pkg', File.basename(artifact))
    FileUtils.cp(artifact, artifact_dest)

    puts "#{spec.name} #{spec.version} built to #{artifact_dest}."
  end
end

task default: :spec

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = './spec/**/*_spec.rb'
end
