require 'test/unit'
require 'dbdom'

require 'jdbc'

PROPERTIES = { :url => 'jdbc:derby:memory:TestDb;create=true' }

Java::Jdbc.with_connection(PROPERTIES) do |conn|
    Java::Jdbc.auto_close(conn.createStatement) do |stmt|
        stmt.execute("create table Boat(id integer, name varchar(20))")
        stmt.execute("insert into Boat (id, name) values (1, 'andy')")
        stmt.execute("insert into Boat (id, name) values (2, 'akiva')")
        stmt.execute("insert into Boat (id, name) values (3, 'jorma')")
    end
end

class DbDomTest < Test::Unit::TestCase
    def test_jdbc
        Java::Jdbc.with_connection(PROPERTIES) do |conn|
            rs = conn.getMetaData.getTables(nil, nil, nil, [ "TABLE" ].to_java(:String))
            Java::Jdbc.auto_close(rs) do |rs|
                assert rs.next
                assert_equal "boat", rs.getString("TABLE_NAME").downcase
            end
        end
    end

    def test_create_dbdocument
        doc = DbDocument.new(nil, PROPERTIES)
        db = doc.root
        assert_equal 1, db.size
        table = db[0]
        assert_equal "boat", table.attributes["name"].downcase
        assert_equal 3, table.size

        table.children.each_with_index do |row, i|
            assert_equal i.to_s, row.attributes["num"]
            assert_equal 2, row.size
            col = row[0]
            assert_equal "id", col.name.downcase
            assert_equal 1, col.size
            text = col[0]
            # ???: dbdom_test.rb:44 warning: (...) interpreted as grouped expression
            assert_equal (i + 1).to_s, text.value
            col = row[1]
            assert_equal "name", col.name.downcase
            assert_equal 1, col.size
            text = col[0]
            assert_equal ["andy", "akiva", "jorma"][i], text.value
        end
    end

    def test_xpath
        doc = DbDocument.new(nil, PROPERTIES)
        #puts doc
        results = XPath.match(doc, '//database');
        assert_equal 1, results.size
        # Rexml does not support predicates? :(
        # http://arrogantgeek.blogspot.com/2008/01/why-ruby-sucks-1.html
        #results = XPath.match(doc, "//table[@name='BOAT'/row/NAME");
        results = XPath.match(doc, "//table/row/NAME/child::text()");
        assert_equal 3, results.size
        who = ""
        results.each { |t| who << t.value << " "}
        puts "On a boat: " + who
    end
end

require 'test/unit/ui/console/testrunner'
Test::Unit::UI::Console::TestRunner.run(DbDomTest)
