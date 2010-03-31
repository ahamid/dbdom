require 'test/unit'

require 'advice'

class BadClass
    def initialize
        @internal_field = "Hi! I'm not designed for extension!"
    end

    def get_the_internal_field
        puts "In super method"
        @internal_field
    end
end

class SubClass < BadClass
    attr_reader :before_called, :after_called, :internal_field

    include Advice

    advise({ :before => :before_advice, :after => :after_advice }, :get_the_internal_field)

    def before_advice(method, *args)
        puts "I'm before!"
        @internal_field = "Overridden"
        @before_called = true
    end

    def after_advice(method, *args)
        puts "I'm after!"
        @after_called = true
    end
end

class AdviceTest < Test::Unit::TestCase
    def test_advice
        s = SubClass.new
        f = s.get_the_internal_field
        assert s.before_called
        assert s.after_called
        assert_equal "Overridden", f
        assert_equal "Overridden", s.internal_field
    end
end


require 'test/unit/ui/console/testrunner'
Test::Unit::UI::Console::TestRunner.run(AdviceTest)
