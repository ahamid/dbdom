require 'java'

require 'rexml'

module DbDom
    def DbDom.createDoc(settings)
        DbDocument.new(nil, settings)
    end

    def DbDom.xpath(node, expr)
        XPath.match(node, expr);
    end
end
