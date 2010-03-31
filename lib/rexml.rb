require 'rexml/document'
include REXML

require 'advice'
require 'jdbc'

module DbDom
    module Rexml

        class DbDom
            def createDoc(settings)
                DbDocument.new(nil, settings)
            end

            def xpath(node, expr)
               XPath.match(node, expr);
            end
        end

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
            def initialize(context)
                super("database", nil, context)
            end

            def init_children
                Util::Jdbc.with_connection(context) do |conn|
                    @children = []            
                    Util::Jdbc.get_tables(conn) do |name|
                        @children << TableElement.new(name, context);
                    end
                end
            end
        end

        class TableElement < DynamicElement
            def initialize(tablename, context)
                super("table", nil, context)
                @tablename = tablename;
                attributes["name"] = tablename;
            end

            def init_children
                Util::Jdbc.with_connection(context) do |conn|
                    rownum = 0
                    Util::Jdbc.get_rows(conn, @tablename) do |row|
                        @children << RowElement.new(rownum, row, context)
                        rownum += 1
                    end
                end
            end
        end

        class RowElement < DynamicElement
            def initialize(rownum, row, context)
                super("row", nil, context)
                @row = row
                attributes["num"] = rownum.to_s;
            end

            def init_children
                column_values = @row.column_values
                @row.column_names.each_with_index do |name, i|
                    col = Element.new(name)
                    data = Text.new(column_values[i], false)
                    col << data
                    self << col
                end
            end

        end

        class DbDocument < Document
            def initialize(source = nil, context = {})
                super(source, context)
                @children << DbElement.new(context)
            end
        end
    end
end
