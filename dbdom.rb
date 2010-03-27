require 'java'
require 'rexml/document'
include REXML

require 'jdbc'
require 'advice'

class DynamicElement < Element
    extend Advice

    # this is super-lame
    # i can't find a way to intercept instance var access
    # and the REXML Parent class does not provide an initialization hook
    # so we basically have to wrap each and every method (well, at least
    # the ones that interact with the @children var), in order to
    # be able to invoke an initialization method
    # either the design of the Parent class sucks, or I'm just missing
    # some great idiomatic way to do this
    EVERY_SINGLE_PARENT_METHOD = [ :add, :push, :<<, :unshift, :delete,
                                   :each, :delete_if, :delete_at, :each_index,
                                   :each_child, :[]=, :insert_before, :insert_after,
                                   :to_a, :index, :size, :length, :children,
                                   :replace_child, :deep_clone ]

    advise_before :initialize_children, *Parent.instance_methods(false)

    def initialize(name, parent, context)
        super(name, parent, context)
        @children_initialized = false
        @initializing = false # hack to avoid re-entrancy
    end

    def initialize_children(method, *args)
        return if @children_initialized || @initializing
        @initializing = true
        init_children
        @children_initialized = true
        @initializing = false
    end

    def init_children
    end
end

class DbElement < DynamicElement
    def initialize(parent, context)
        super("database", parent, context)
    end

    def init_children
        Java::Jdbc.with_connection(context) do |conn|
            rs = conn.getMetaData.getTables(nil, nil, nil, [ "TABLE" ].to_java(:String))
            @children = []
            Java::Jdbc.auto_close(rs) do |rs|
                while rs.next do
                    @children << TableElement.new(rs.getString("TABLE_NAME"), nil, context);
                end
            end
        end
    end
end

class TableElement < DynamicElement
    def initialize(tablename, parent, context)
        super("table", parent, context)
        @tablename = tablename;
        attributes["name"] = tablename;
    end

    def init_children
        Java::Jdbc.with_connection(context) do |conn|
            Java::Jdbc.auto_close(conn.createStatement) do |stmt|
                rs = stmt.executeQuery("select * from " + @tablename)
                Java::Jdbc.auto_close(rs) do |rs|
                    metadata = rs.getMetaData
                    column_names = []
                    1.upto(metadata.getColumnCount) do |i|
                        column_names << metadata.getColumnName(i)
                    end
                    rownum = 0
                    while rs.next do
                        @children << construct_row(rs, column_names, rownum)
                        rownum += 1
                    end
                end
            end
        end
    end

    def construct_row(rs, column_names, rownum)
        row = Element.new("row");
        row.attributes["num"] = rownum.to_s
        column_names.each_with_index do |name, i|
            col = Element.new(name)
            data = Text.new(rs.getString(i + 1), false)
            col << data
            row << col
        end
        return row
    end
end

class DbDocument < Document
    def initialize(source = nil, context = {})
        super(source, context)
        @children << DbElement.new(nil, context)
    end
end
