pragma Singleton

import QtQuick

// Qt Quick has no clipboard API, so copy through a hidden TextEdit.
Item {
    id: root

    signal copied(string what)

    function copy(text: string, what: string): void {
        edit.text = text;
        edit.selectAll();
        edit.copy();
        edit.deselect();
        root.copied(what || "Copied");
    }

    visible: false

    TextEdit {
        id: edit

        visible: false
    }
}
