/*
 * Copyright (C) 2016 Stefano Verzegnassi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/.
 */

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import Ubuntu.Components.Themes.SuruDark 1.1

MainView {
    id: root
      
    Timer {
        id: timerquit
        interval: 1000      // 2 secondes
        running: false
        repeat: false
        onTriggered: Qt.quit()
    }
Page {
    id: picker
    theme.name: "Ubuntu.Components.Themes.SuruDark"
	property var activeTransfer

	property var url
	property var handler: ContentHandler.Source
	property var contentType: ContentType.All

    signal cancel()
    signal imported(string fileUrl)

    header: PageHeader {
        title: i18n.tr("Choose")
        }
    
    ContentPeerPicker {
        anchors { fill: parent; topMargin: picker.header.height }
        visible: parent.visible
        showTitle: false
        contentType: picker.contentType
        handler: picker.handler //ContentHandler.Source

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            picker.activeTransfer = peer.request()
            picker.activeTransfer.stateChanged.connect(function() {
                // Upload is done in Perl
                // we only need to close the Import Page Window and wait
                // for file changes in HubIncoming directory
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                   // All we need to do here is close the window, because the import 
                   // is handled entirely in Perl (see import_path() in ContentHub.pm)
                   timerquit.running=true;
                   // picker.activeTransfer = null;
                }
            })
        }


        onCancelPressed: {
            console.log("Cancelled")
            //TODO handle cancel
        }
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: picker.activeTransfer
    }
    Component {
        id: resultComponent
        ContentItem {}
	}
    }    
}
