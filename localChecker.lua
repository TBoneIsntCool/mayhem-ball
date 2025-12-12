local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a value for clients to read
local licenseValue = Instance.new("BoolValue")
licenseValue.Name = "LicenseEnabled"
licenseValue.Value = false
licenseValue.Parent = ReplicatedStorage

local url = "https://raw.githubusercontent.com/TBoneIsntCool/mayhem-ball/refs/heads/main/license.txt"

local ok, license = pcall(function()
	return HttpService:GetAsync(url)
end)

if ok then
    license = tostring(license):lower():gsub("%s+", "")
    if license == "enabled" then
        licenseValue.Value = true
        print("[LICENSE] Enabled")
    else
        print("[LICENSE] Disabled")
    end
else
    print("[LICENSE] HTTP ERROR")
end
