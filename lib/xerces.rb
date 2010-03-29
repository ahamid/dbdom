require 'rubygems'
require 'xercesImpl'
require 'java'

import org.apache.xerces.dom.ElementImpl
import org.apache.xerces.dom.CoreDocumentImpl

module DbDom
    module Xerces

        class DbDom
            def createDoc(settings)
                DatabaseDocument.new(settings)
            end

            def xpath(node, expr)
                xpath = javax.xml.xpath.XPathFactory.newInstance.newXPath
                xpath.evaluate(expr, node, javax.xml.xpath.XPathConstants::NODESET)
            end
        end

        class DatabaseElement < org.apache.xerces.dom.ElementImpl
            def initialize(doc)
                super(doc, "database")
                needsSyncChildren(true)
                @updating = false
            end

            def synchronizeChildren
                return if @updating # avoid re-entrancy
                @updating = true
                Java::Jdbc.with_connection(ownerDocument.settings) do |conn|
                    Java::Jdbc.get_tables(conn) do |name|
                        appendChild(TableElement.new(ownerDocument, name));
                    end
                end
                super
                @updating = false
            end
        end

        class TableElement < org.apache.xerces.dom.ElementImpl
            def initialize(doc, name)
                super(doc, "table")
                needsSyncChildren(true)
                setAttribute("name", name)
                @name = name
                @updating = false
            end

            def synchronizeChildren
                return if @updating # avoid re-entrancy
                @updating = true
                Java::Jdbc.with_connection(ownerDocument.settings) do |conn|
                    rownum = 0
                    Java::Jdbc.get_rows(conn, @name) do |column_names, column_values|
                        appendChild(construct_row(column_names, column_values, rownum))
                        rownum += 1
                    end
                end
                super
                @updating = false
            end

            private
                # this implementation just grabs all rows
                # don't iterate the resultset on demand or implement
                # any optimizations based on specific Element navigation calls
                def construct_row(column_names, column_values, rownum)
                    row = ownerDocument.createElement("row");
                    row.setAttribute("num", rownum.to_s)
                    column_names.each_with_index do |name, i|
                        col = ownerDocument.createElement(name)
                        data = ownerDocument.createTextNode(column_values[i])
                        col.appendChild(data)
                        row.appendChild(col)
                    end
                    return row
                end
        end

        class DatabaseDocument < org.apache.xerces.dom.CoreDocumentImpl
            # http://jira.codehaus.org/browse/JRUBY-2457
            def initialize(settings)
                @settings = settings
                super()
                needsSyncChildren(true)
                @docElement = DatabaseElement.new(self)
                # we need to append the doc root
                # (which makes sense but hadn't done it when I was just using DOM)
                # xpath relies on this
                appendChild(@docElement)
            end

            attr_reader :settings
           
            # Note: for some reason calling this class with 'docElement'
            # did not result in this method being invoked
            # I moved the initialization to the constructor
            # this method was implemented because synchronizeChildren didn't
            # appear to be getting called in the first place 
            def getDocumentElement
            #def synchronizeChildren
            #    puts "SYNCING"
                @docElement
            #    super
            end
        end
    end
end
