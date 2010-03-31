# simple advice support
# see: http://refactormycode.com/codes/656-method-hooks-in-ruby-any-cleaner
module Advice
    module ClassMethods
        def advise_before(sym, *methods)
            advise({ :before => sym }, *methods)    
        end

        def advise_after(sym, *methods)
            advise({ :after => sym }, *methods)    
        end

        def advise(h = {}, *methods)
            methods.each do |meth|
                # save original method
                hook_method = RUBY_VERSION >= '1.9.0' ? :"__#{meth}__hooked__" : "__#{meth}__hooked__"
                # create the copy of the hooked method          
                alias_method hook_method, meth
                # declare the original private
                private hook_method

                # define our new replacement method
                define_method meth do |*args|
                    if h.has_key?(:before)
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

        # this only works with methods that do no return a value
        # because they need to be short-circuited
        def short_circuit_recursion(meth)
            puts "configuring short circuit for meth #{meth}"

            hook_method = RUBY_VERSION >= '1.9.0' ? :"__#{meth}__recursable__" : "__#{meth}__recursable__"
            # create the copy of the hooked method          
            alias_method hook_method, meth
            # declare the original private
            private hook_method

            # define our new replacement method that checks if it has been
            # entered first
            define_method meth do |*args|
                private_field = "@__#{meth}_entered__"
                has_entered = instance_variable_get(private_field) 
                # short-circuit the call if it is an ancestor on the call stack!
                return if (has_entered == true)
                instance_variable_set(private_field, true)

                # call the original method
                send(:"__#{meth}__recursable__", *args)

                instance_variable_set(private_field, false)
            end    
        end
    end

    def self.included(base)
        base.extend(ClassMethods)
    end

end
