require 'java'

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
            end

            def synchronizeChildren
                Java::Jdbc.with_connection(getOwnerDocument.settings) do |conn|
                    Java::Jdbc.get_tables(conn) do |name|
                        appendChild(TableElement.new(getOwnerDocument, name));
                    end
                end
                super
            end
        end

        class TableElement < org.apache.xerces.dom.ElementImpl
            def initialize(doc, name)
                super(doc, name)
                needsSyncChildren(true)
            end

            def synchronizeChildren
                Java::Jdbc.with_connection(getOwnerDocument.settings) do |conn|
                    rownum = 0
                    Java::Jdbc.get_rows(conn, getNodeName) do |column_names, column_values|
                        appendChild(construct_row(column_names, column_values, rownum))
                        rownum += 1
                    end
                end
                super
            end

            private
                # this implementation just grabs all rows
                # don't iterate the resultset on demand or implement
                # any optimizations based on specific Element navigation calls
                def construct_row(column_names, column_values, rownum)
                    row = getOwnerDocument.createElement("row");
                    row.attributes["num"] = rownum.to_s
                    column_names.each_with_index do |name, i|
                        col = getOwnerDocument.createElement(getOwnerDocument, name)
                        data = getOwnerDocument.createTextNode(column_values[i])
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
            end

            attr_reader :settings
            
            def getDocumentElement
            #def synchronizeChildren
            #    puts "SYNCING"
                @docElement = DatabaseElement.new(self)
            #    super
            end
        end
    end
end
