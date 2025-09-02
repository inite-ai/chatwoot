# Load all rake tasks from the enterprise/lib/tasks directory
# Only load rake files when we're actually in a Rake task context
module Tasks
  # Check if we're running rake command or if Rake DSL is available
  if defined?(::Rake::DSL) || (defined?(Rake) && Rake.respond_to?(:application))
    Dir.glob(File.join(File.dirname(__FILE__), 'tasks', '*.rake')).each { |r| load r }
  end
end
