class MethodCounter
  def self.count_calls_to(full_method_name)
    matches = full_method_name.match(/^(.*?)([\.#])(.*)$/)
    class_name, separator, method_name = matches[1..3]
    singleton = false
    prefix = 'instance'
    if separator == '.'
      singleton = true
      prefix = 'singleton'
    end


    call_count = 0

    Class.class_eval do
      define_method("inherited_with_#{class_name}_check") do |inherited_by|
        if inherited_by.to_s == class_name
          puts "#{inherited_by} is #{class_name}"
          class_const = Kernel.const_get(class_name)

          class_const.class_eval do
            def self.method_added(foo)
              puts "#{foo} added"
            end
          end


          at_exit do
            # if rails, use pluralize for cleanliness.
            puts "#{full_method_name} called #{call_count} times"
          end
        end
        send("inherited_without_#{class_name}_check", inherited_by)
      end

      alias_method "inherited_without_#{class_name}_check", 'inherited'
      alias_method 'inherited', "inherited_with_#{class_name}_check"
    end

  end

end

if ENV['COUNT_CALLS_TO']
  MethodCounter.count_calls_to(ENV['COUNT_CALLS_TO'])
  # could also split this env by comma and instrument multiple methods
end

__END__
          class_const.class_eval do
            def self.method_added(foober)
              puts "#{foober} added"
            end
            define_singleton_method("method_added_with_#{prefix}_#{method_name}_check") do |method_added_name|
              puts "method added #{method_added_name}"
              if method_added_name.to_s == method_name
                if singleton
                  define_singleton_method("#{method_name}_with_count") do |*args, &block|
                    puts "#{method_name} called"
                    call_count += 1
                    send("#{method_name}_without_count", *args, &block)
                  end

                  class_const.singleton_class.send('alias_method', "#{method_name}_without_count", "#{method_name}")
                  class_const.singleton_class.send('alias_method', "#{method_name}", "#{method_name}_with_count")

                else
                  define_method("#{method_name}_with_count") do |*args, &block|
                    puts "#{method_name} called"
                    call_count += 1
                    send("#{method_name}_without_count", *args, &block)
                  end

                  alias_method "#{method_name}_without_count", "#{method_name}"
                  alias_method "#{method_name}", "#{method_name}_with_count"
                end
              end
              send("method_added_without_#{method_name}_check", method_added_name)
            end

            class_const.singleton_class.send('alias_method', "method_added_without_#{prefix}_#{method_name}_check", 'method_added')
            class_const.singleton_class.send('alias_method', 'method_added', "method_added_with_#{prefix}_#{method_name}_check")
          end
