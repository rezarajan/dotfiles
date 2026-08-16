var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "ItemGeometries-3127x1309": "",
                    "ItemGeometries-3440x1440": "Applet-48:2704,16,240,192,0;Applet-49:2944,16,224,192,0;Applet-38:3184,48,224,128,0;Applet-51:3200,192,208,128,0;",
                    "ItemGeometriesHorizontal": "",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "630",
                    "DialogWidth": "810"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///usr/share/wallpapers/cachyos-wallpapers/Cachy_Topography.jpg",
                    "SlidePaths": "/usr/share/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/Appearance": {
                            "fixedLength": "215",
                            "hideWhenUnavailable": "true",
                            "lengthKind": "2"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "687",
                            "DialogWidth": "1113"
                        }
                    },
                    "plugin": "org.kde.plasma.windowtitlereborn"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "400",
                            "popupWidth": "560"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        }
                    },
                    "plugin": "org.kde.plasma.appmenu"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.panelspacer"
                },
                {
                    "config": {
                        "/": {
                            "CurrentPreset": "org.kde.plasma.systemmonitor",
                            "popupHeight": "400",
                            "popupWidth": "560"
                        },
                        "/Appearance": {
                            "chartFace": "org.kde.ksysguard.linechart",
                            "title": "Network Speed"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/FaceGrid/Appearance": {
                            "chartFace": "org.kde.ksysguard.linechart",
                            "showTitle": "false"
                        },
                        "/FaceGrid/SensorColors": {
                            "network/all/download": "61,174,233",
                            "network/all/upload": "233,120,61"
                        },
                        "/FaceGrid/Sensors": {
                            "highPrioritySensorIds": "[\"network/all/upload\"]"
                        },
                        "/SensorColors": {
                            "network/all/download": "61,174,233",
                            "network/all/upload": "233,120,61"
                        },
                        "/Sensors": {
                            "highPrioritySensorIds": "[\"network/all/download\",\"network/all/upload\"]"
                        },
                        "/org.kde.ksysguard.linechart/General": {
                            "lineChartStacked": "true",
                            "showLegend": "false"
                        }
                    },
                    "plugin": "org.kde.plasma.systemmonitor.net"
                },
                {
                    "config": {
                        "/": {
                            "CurrentPreset": "org.kde.plasma.systemmonitor",
                            "popupHeight": "160",
                            "popupWidth": "156"
                        },
                        "/Appearance": {
                            "chartFace": "org.kde.ksysguard.linechart",
                            "showTitle": "true",
                            "title": "Memory Usage"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/FaceGrid/Appearance": {
                            "chartFace": "org.kde.ksysguard.linechart",
                            "showTitle": "false"
                        },
                        "/FaceGrid/SensorColors": {
                            "memory/physical/used": "61,174,233"
                        },
                        "/FaceGrid/Sensors": {
                            "highPrioritySensorIds": "[\"memory/physical/used\"]"
                        },
                        "/SensorColors": {
                            "memory/physical/used": "61,174,233"
                        },
                        "/Sensors": {
                            "highPrioritySensorIds": "[\"memory/physical/used\"]",
                            "lowPrioritySensorIds": "[\"memory/physical/total\"]",
                            "totalSensors": "[\"memory/physical/usedPercent\"]"
                        },
                        "/org.kde.ksysguard.colorgrid/General": {
                            "useSensorColor": "false"
                        }
                    },
                    "plugin": "org.kde.plasma.systemmonitor.memory"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "451",
                            "popupWidth": "810"
                        },
                        "/Appearance": {
                            "dateFormat": "isoDate",
                            "enabledCalendarPlugins": "alternatecalendar",
                            "showDate": "false",
                            "use24hFormat": "2"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            },
            "height": 1.5,
            "hiding": "normal",
            "lengthMode": "fill",
            "location": "top",
            "maximumLength": 173.72222222222223,
            "minimumLength": 173.72222222222223,
            "offset": 0,
            "opacity": "adaptive"
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
