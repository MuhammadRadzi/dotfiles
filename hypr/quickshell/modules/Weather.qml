import QtQuick
import Quickshell.Io
import "../theme"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

    property string weatherText: "..."

    Text {
        id: label
        anchors.centerIn: parent
        text: weatherText
        color: Colors.text
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
    }

    Process {
        id: weatherProc
        command: [
            "sh", "-c",
            "curl -s 'https://api.openweathermap.org/data/2.5/weather?q=Makassar&appid=0c412ffb108b6d65566ca3fde0c7bed2&units=metric' | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d['weather'][0]['main']+'|'+str(round(d['main']['temp']))+'|'+str(d['main']['humidity']))\""
        ]
        stdout: SplitParser {
            onRead: data => {
                if (!data || data.trim() === "") return
                var parts = data.trim().split("|")
                var cond = parts[0] || ""
                var temp = parts[1] || "?"
                var hum  = parts[2] || "?"

                var icon = "🌡"
                if (cond === "Clear")        icon = "󰖙"
                else if (cond === "Clouds")  icon = "󰖐"
                else if (cond === "Rain")    icon = "󰖗"
                else if (cond === "Drizzle") icon = "󰖔"
                else if (cond === "Thunder" || cond === "Thunderstorm") icon = "󰖓"
                else if (cond === "Snow")    icon = "󰖘"
                else if (cond === "Mist" || cond === "Fog" || cond === "Haze") icon = "󰖑"

                weatherText = icon + " " + temp + "°C  󰖝 " + hum + "%"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 600000  // update tiap 10 menit
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }
}