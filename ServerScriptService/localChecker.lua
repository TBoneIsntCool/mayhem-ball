local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local licenseValue = Instance.new("BoolValue")
licenseValue.Name = "LicenseEnabled"
licenseValue.Value = false
licenseValue.Parent = ReplicatedStorage

local ok, license = pcall(function()
	return HttpService:GetAsync("https://raw.githubusercontent.com/TBoneIsntCool/mayhem-ball/refs/heads/main/license.txt")
end)

if ok then
	license = tostring(license):lower():gsub("%s+", "")
	if license == "enabled" then
		licenseValue.Value = true
	else
		licenseValue.Value = false
	end
else
	licenseValue.Value = false
end
