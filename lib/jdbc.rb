require 'java'

module Util
    module Jdbc
        # this is apparently not necessary in Java 1.6+
        # it implements some sort of automatic driver loading
        def Jdbc.load_driver(driver_class)
            puts "Loading driver: " + driver_class
            java.lang.Class.for_name(driver_class)
            #Java::JavaClass.for_name(driver_class)
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

        def Jdbc.get_tables(conn)
            rs = conn.getMetaData.getTables(nil, nil, nil, [ "TABLE" ].to_java(:String))
            auto_close(rs) do |rs|
                while rs.next do
                    yield rs.getString("TABLE_NAME")
                end
            end
        end

        def Jdbc.get_rows(conn, tablename)
            auto_close(conn.createStatement) do |stmt|
                rs = stmt.executeQuery("select * from " + tablename)
                auto_close(rs) do |rs|
                    metadata = rs.getMetaData
                    column_names = []
                    1.upto(metadata.getColumnCount) do |i|
                        column_names << metadata.getColumnName(i)
                    end
                    while rs.next do
                        column_values = []
                        column_names.each_with_index do |name, i|
                            column_values << rs.getString(i + 1)
                        end
                        yield column_names, column_values
                    end
                end
            end
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
