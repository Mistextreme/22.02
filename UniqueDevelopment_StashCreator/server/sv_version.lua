if not Config.CheckVersion then return end

local resourceName = GetCurrentResourceName()
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)

CreateThread(function()
    PerformHttpRequest(
        'https://raw.githubusercontent.com/UniqueDevelopment/versions/main/StashCreator.txt',
        function(statusCode, response, headers)
            if statusCode == 200 and response then
                local latestVersion = response:gsub('%s+', '')

                if currentVersion ~= latestVersion then
                    print(string.format(
                        '^3[%s]^0 A new version is available: ^2%s^0 (current: ^1%s^0)',
                        resourceName, latestVersion, currentVersion
                    ))
                    print(string.format(
                        '^3[%s]^0 Download the latest version at: ^5https://discord.gg/bpWYsC5juV^0',
                        resourceName
                    ))
                else
                    print(string.format(
                        '^2[%s]^0 Resource is up to date (v%s)',
                        resourceName, currentVersion
                    ))
                end
            else
                if Config.Debug then
                    print(string.format(
                        '^1[%s]^0 Could not check version (status: %s)',
                        resourceName, tostring(statusCode)
                    ))
                end
            end
        end,
        'GET', '', {}
    )
end)
