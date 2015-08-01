class MethodCounter
  def self.count_calls_to(full_method_name)
    class_name, method_name = full_method_name.split(/[\.#]/)
    class_const = Kernel.const_get(class_name)

    call_count = 0

    class_const.class_eval do
      define_method("#{method_name}_with_count") do |*args, &block|
        call_count += 1
        send("#{method_name}_without_count", *args, &block)
      end

      alias_method "#{method_name}_without_count", "#{method_name}"
      alias_method "#{method_name}", "#{method_name}_with_count"
    end

    at_exit do
      # if rails, use pluralize for cleanliness.
      puts "#{full_method_name} called #{call_count} times"
    end
  end

end

if ENV['COUNT_CALLS_TO']
  # could also split this env by comma and instrument multiple methods
  MethodCounter.count_calls_to(ENV['COUNT_CALLS_TO'])
end
