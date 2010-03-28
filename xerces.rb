require 'java'

module Java
    module Xerces

        DatabaseDocument < org.apache.xerces.internal.dom.CoreDocumentImpl
            def initialize(settings)
                @settings = settings
            end

            def synchronizeChildren
            end
        end
    end
end
