local generalOptions = {
    name = appName .. ": General",
    handler = DLTAddOn,
    type = "group",
    args = {
        info = {
            type = "header",
            name = "",
            desc = ""
        },
        autoRecord = {
            type = "toggle",
            name = "Auto Record",
            desc = "Do you want to start recording as soon as you enter an instance without being asked?",
            get = "getAutoRecord",
            set = "setAutoRecord"
        },
    }
}
