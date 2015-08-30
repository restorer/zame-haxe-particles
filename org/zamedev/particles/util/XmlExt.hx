package org.zamedev.particles.util;

class XmlExt {
    public static function innerText(node : Xml, def : String = "") : String {
        var child = node.firstChild();

        if (child != null && (child.nodeType == Xml.PCData || child.nodeType == Xml.CData)) {
            return child.nodeValue;
        }

        return def;
    }
}
