import QtQuick
import QtQuick.Window
import "components"
import "pages"

Window {
    id: window

    property int currentPage: 0

    width: 1100
    height: 720
    minimumWidth: 880
    minimumHeight: 600
    visible: true
    title: "My Linux T248R Panel"
    color: Colours.m3surface

    function go(index: int): void {
        currentPage = Math.max(0, Math.min(pages.length - 1, index));
    }

    readonly property var destinations: [
        { icon: "home", label: "Home" },
        { icon: "search_hands_free", label: "Wheel test" },
        { icon: "auto_transmission", label: "Shifter" },
        { icon: "tune", label: "Force feedback" },
        { icon: "help", label: "Help" }
    ]
    readonly property list<Item> pages: [home, wheelTest, shifter, forceFeedback, help]

    StyledRect {
        anchors.fill: parent
        color: Colours.m3surface
    }

    NavRail {
        id: rail

        // Above the page area, so tooltips from the rail can reach over it.
        z: 1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        model: window.destinations
        currentIndex: window.currentPage
        onActivated: index => window.go(index)

        WheelStatus {}
    }

    StyledRect {
        id: content

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.margins: 12
        anchors.leftMargin: 0
        radius: Appearance.rounding.extraLargeIncreased
        color: Colours.m3surfaceContainerLow
        clip: true

        Item {
            id: host

            property Item shown: null

            anchors.fill: parent
            // Render the pages into one texture. Without it, curve-rendered shapes from a hidden or
            // scrolled page can show up in the margin outside the clip (seen with Qt 6.12).
            layer.enabled: true

            // Shared Y axis transition: the old page lifts away and fades, the new one springs in
            // from the side you are moving towards.
            function show(index: int): void {
                const next = window.pages[index];
                const prev = shown;
                if (next === prev)
                    return;
                if (outAnim.running)
                    outAnim.complete();
                if (inAnim.running)
                    inAnim.complete();

                const dir = prev && window.pages.indexOf(prev) > index ? -1 : 1;
                if (prev) {
                    outAnim.page = prev;
                    outY.to = -dir * 24;
                    outAnim.start();
                }
                next.y = dir * 56;
                next.opacity = 0;
                next.visible = true;
                inAnim.page = next;
                inAnim.start();
                shown = next;
            }

            Component.onCompleted: {
                for (const p of window.pages)
                    p.visible = false;
                show(window.currentPage);
            }

            Connections {
                target: window

                function onCurrentPageChanged(): void {
                    host.show(window.currentPage);
                }
            }

            ParallelAnimation {
                id: outAnim

                property Item page

                onFinished: {
                    page.visible = false;
                    page.y = 0;
                }

                Anim {
                    target: outAnim.page
                    property: "opacity"
                    to: 0
                    type: Anim.FastEffects
                }
                Anim {
                    id: outY

                    target: outAnim.page
                    property: "y"
                    type: Anim.EmphasizedAccel
                }
            }

            ParallelAnimation {
                id: inAnim

                property Item page

                SequentialAnimation {
                    PauseAnimation {
                        duration: 70
                    }
                    Anim {
                        target: inAnim.page
                        property: "opacity"
                        to: 1
                        type: Anim.DefaultEffects
                    }
                }
                Anim {
                    target: inAnim.page
                    property: "y"
                    to: 0
                    type: Anim.DefaultSpatial
                }
            }

            HomePage {
                id: home

                width: host.width
                height: host.height
                onNavigate: index => window.go(index)
            }
            WheelPage {
                id: wheelTest

                width: host.width
                height: host.height
                onNavigate: index => window.go(index)
            }
            ShifterPage {
                id: shifter

                width: host.width
                height: host.height
            }
            ForceFeedbackPage {
                id: forceFeedback

                width: host.width
                height: host.height
                onNavigate: index => window.go(index)
            }
            HelpPage {
                id: help

                width: host.width
                height: host.height
                onNavigate: index => window.go(index)
                onUninstallRequested: uninstallDialog.open()
            }
        }
    }

    ConfirmDialog {
        id: uninstallDialog

        objectName: "uninstallDialog"

        icon: "delete_forever"
        danger: true
        title: "Undo everything?"
        text: "This removes the force feedback driver, the wheel permissions and your saved settings. Your wheel goes back to the generic driver, without force feedback. You'll be asked for your password."
        confirmText: "Remove"
        onAccepted: {
            Setup.uninstall();
            window.go(0);
        }
    }

    Snackbar {
        id: snackbar

        objectName: "snackbar"
    }

    Connections {
        target: Clipboard

        function onCopied(what: string): void {
            snackbar.show(what, false);
        }
    }

    Connections {
        target: Setup

        function onFinished(ok: bool): void {
            if (ok)
                snackbar.show("Done", false);
            else
                snackbar.show(Setup.lastError || "That didn't work. Check the log on Home.", true);
        }
    }

    Shortcut {
        sequences: ["Ctrl+1"]
        onActivated: window.go(0)
    }
    Shortcut {
        sequences: ["Ctrl+2"]
        onActivated: window.go(1)
    }
    Shortcut {
        sequences: ["Ctrl+3"]
        onActivated: window.go(2)
    }
    Shortcut {
        sequences: ["Ctrl+4"]
        onActivated: window.go(3)
    }
    Shortcut {
        sequences: ["Ctrl+5"]
        onActivated: window.go(4)
    }
    Shortcut {
        sequences: ["Escape"]
        enabled: uninstallDialog.shown
        onActivated: uninstallDialog.close()
    }
}
