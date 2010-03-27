# simple advice support
# see: http://refactormycode.com/codes/656-method-hooks-in-ruby-any-cleaner
module Advice
    def advise_before(sym, *methods)
        advise({ :before => sym }, *methods)    
    end

    def advise_after(sym, *methods)
        advise({ :after => sym }, *methods)    
    end

    def advise(h = {}, *methods)
        methods.each do |meth|
            puts "Advising: " + meth.to_s
            # save original method
            hook_method = RUBY_VERSION >= '1.9.0' ? :"__#{meth}__hooked__" : "__#{meth}__hooked__"
            # create the copy of the hooked method          
            alias_method hook_method, meth
            # declare the original private
            private hook_method

            # define our new replacement method
            define_method meth do |*args|
                if h.has_key?(:before)
                    puts "Calling"
                    method(h[:before]).call meth, args
                end
                # call the original method
                val = send(:"__#{meth}__hooked__", *args)
                if h.has_key?(:after)
                    method(h[:after]).call meth, args
                end
                val
            end
        end
    end
end
