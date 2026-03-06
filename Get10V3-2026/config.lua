-----------------------------------------------------------------------------------------
--
-- config.lua
-- Get10 - Display / Content Configuration
--
-- Targets a virtual 320 x 568 canvas that letterboxes on all devices.
-- Image suffix "@2" activates for screens >1.5× base density.
--
-----------------------------------------------------------------------------------------

application = {
    content = {
        width   = 320,
        height  = 568,
        fps     = 60,
        scale   = "letterBox",
        xAlign  = "center",
        yAlign  = "center",
        imageSuffix = {
            ["@2"] = 1.5,
            ["@4"] = 3.0,
        },
    },
}
