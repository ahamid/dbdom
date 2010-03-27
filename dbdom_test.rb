require 'test/unit'
require 'dbdom'

class DbDomTest < Test::Unit::TestCase
    def setup
        @context = { :url => 'jdbc:derby:memory:TestDb;create=true' }

        Java::Jdbc.with_connection(@context) do |conn|
            Jdbc.auto_close(conn.createStatement) do |stmt|
                stmt.execute("create table Foo(id integer)")
            end
        end
    end

    def teardown
    end

    def test_jdbc
        Java::Jdbc.with_connection(@context) do |conn|
            rs = conn.getMetaData.getTables(nil, nil, nil, [ "TABLE" ].to_java(:String))
            Java::Jdbc.auto_close(rs) do |rs|
                assert rs.next
                assert_equal "FOO", rs.getString("TABLE_NAME")
            end
        end
    end

    def test_create_dbdocument
        d = DbDocument.new(nil, :user => "me")
    end
end

require 'test/unit/ui/console/testrunner'
Test::Unit::UI::Console::TestRunner.run(DbDomTest)
