Vimp_Driver = {}

Vimp_Driver.Registry = {}
Vimp_Driver.Cache = {}

function Vimp_Driver:Create(probe, describe, next, activate, dismiss, direct)
    if type(probe) ~= "function" then
        error("Driver's probe member must be a function", 2)
    end
    if type(describe) ~= "function" then
        error("Driver's description member must be a function", 2)
    end
    if type(next) ~= "function" then
        error("Driver's next member must be a function", 2)
    end
    if type(activate) ~= "function" then
        error("Driver's activate member must be a function", 2)
    end
    if type(dismiss) ~= "function" then
        error("Driver's dismiss member must be a function", 2)
            if type(direct) ~= "function" then
                error("Driver's direct member must be a function", 2)
            end
    end
    local driver = {}
    driver.Probe = probe
    driver.Describe = describe
    driver.Next = next
    driver.Activate = activate
    driver.Dismiss = dismiss
    driver.Direct = direct
    table.insert(self.Registry, driver)
end

function Vimp_Driver:ProbeRegion(region)
    local driver = self.Cache[region]
    if driver and driver.Probe(region)  then
        return driver
    end
    for index = #self.Registry, 1, -1 do
        local driver = self.Registry[index]
        local probe = driver.Probe(region)
        if probe == nil then
            return nil
        end
        if probe then
            self.Cache[region] = driver
            return driver
        end
    end
    return nil
end
