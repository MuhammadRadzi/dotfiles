import "../theme"
import QtQuick
import Quickshell.Io

Item {
    property string weatherText: "..."

    implicitWidth: label.implicitWidth
    implicitHeight: parent.height

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

        command: ["bash", "-c", "KEY=$(cat /home/murasa/.config/hypr/.env.local | grep OPENWEATHER_KEY | cut -d= -f2) && curl -s 'https://api.openweathermap.org/data/2.5/weather?q=Makassar&appid='\"$KEY\"'&units=metric' | python3 -c \"import sys,json; d=json.load(sys.stdin); print(d['weather'][0]['main']+'|'+str(round(d['main']['temp']))+'|'+str(d['main']['humidity']))\""]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data || data.trim() === "")
                    return ;

                var parts = data.trim().split("|");
                var cond = parts[0] || "";
                var temp = parts[1] || "?";
                var hum = parts[2] || "?";
                var icon = "🌡";
                if (cond === "Clear")
                    icon = "󰖙";
                else if (cond === "Clouds")
                    icon = "󰖐";
                else if (cond === "Rain")
                    icon = "󰖗";
                else if (cond === "Drizzle")
                    icon = "󰖔";
                else if (cond === "Thunder" || cond === "Thunderstorm")
                    icon = "󰖓";
                else if (cond === "Snow")
                    icon = "󰖘";
                else if (cond === "Mist" || cond === "Fog" || cond === "Haze")
                    icon = "󰖑";
                weatherText = icon + " " + temp + "°C  󰖝 " + hum + "%";
            }
        }

    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

}
