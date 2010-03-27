require 'java'

module Java
    module Jdbc
        # this is apparently not necessary in Java 1.6+
        # it implements some sort of automatic driver loading
        def Jdbc.load_driver(driver_class)
            Java::JavaClass.for_name(driver_class)
        end

        def Jdbc.get_connection(url, user, password)
            return java.sql.DriverManager.getConnection(url, user, password)
        end

        def Jdbc.auto_close(object, &block)
            begin
                block.call object
            ensure
                object.close
            end
        end

        def Jdbc.with_connection(context, &block)
            load_driver(context[:driver_class]) if context.has_key?(:driver_class)
            conn = get_connection(context[:url], context[:user], context[:password])
            auto_close(conn, &block)
        end

        # TODO: determine if it's possible to just alias Module class methods        
        #alias :with_statement :auto_close
        #alias :with_resultset :auto_close
        def Jdbc.with_statement(object, &block)
            auto_close(object, &block)
        end
        def Jdbc.with_resultset(object, &block)
            auto_close(object, &block)
        end
    end
end
