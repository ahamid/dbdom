require 'rubygems'
require 'xercesImpl'
require 'java'
require 'jdbc'

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
            include Advice

            def initialize(doc)
                super(doc, "database")
                needsSyncChildren(true)
            end

            def synchronizeChildren
                Util::Jdbc.with_connection(getOwnerDocument.settings) do |conn|
                    Util::Jdbc.get_tables(conn) do |name|
                        appendChild(TableElement.new(ownerDocument, name));
                    end
                end
                super
            end

            short_circuit_recursion :synchronizeChildren
        end

        class TableElement < org.apache.xerces.dom.ElementImpl
            include Advice

            def initialize(doc, name)
                super(doc, "table")
                needsSyncChildren(true)
                setAttribute("name", name)
                @name = name
            end

            def synchronizeChildren
                puts "Getting all rows for table: " + getAttribute("name")
                Util::Jdbc.with_connection(ownerDocument.settings) do |conn|
                    rownum = 0
                    Util::Jdbc.get_rows(conn, @name) do |row|
                        appendChild(RowElement.new(ownerDocument, rownum, row))
                        rownum += 1
                    end
                end
                super
            end

            short_circuit_recursion :synchronizeChildren
        end

        class RowElement < org.apache.xerces.dom.ElementImpl
            include Advice

            def initialize(doc, rownum, row)
                super(doc, "row")
                setAttribute("num", rownum.to_s)  
                @row = row    
                needsSyncChildren(true)
            end

            def synchronizeChildren
                column_values = @row.column_values
                @row.column_names.each_with_index do |name, i|
                    col = ownerDocument.createElement(name)
                    val = ownerDocument.createTextNode(column_values[i])
                    col.appendChild(val)
                    appendChild(col)
                end            
                super
            end

            short_circuit_recursion :synchronizeChildren
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
