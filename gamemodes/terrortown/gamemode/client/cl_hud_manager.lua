ttt_include("vgui__cl_hudswitcher")

local current_hud_cvar = CreateClientConVar("ttt2_current_hud", HUDManager.defaultHUD or "pure_skin", true, true)

function HUDManager.ShowHUDSwitcher()
	local client = LocalPlayer()

	if IsValid(client.hudswitcher) then
		client.hudswitcher.forceClosing = true

		client.hudswitcher:Remove()
	end

	client.hudswitcher = vgui.Create("HUDSwitcher")

	if client.hudswitcherSettingsF1 then
		client.settingsFrame = client.hudswitcher
	end

	client.hudswitcher:MakePopup()
end

function HUDManager.HideHUDSwitcher()
	local client = LocalPlayer()

	if IsValid(client.hudswitcher) then
		-- this will differentiate between user closed and closed by this method,
		-- so that this method is called when the user closed the frame by clicking on the X button
		client.hudswitcher.forceClosing = true

		client.hudswitcher:Remove()
	end

	if not client.settingsFrameForceClose and not HUDEditor.IsEditing then
		HELPSCRN:Show()
	end
end

function HUDManager.DrawHUD()
	local hud = huds.GetStored(HUDManager.GetHUD())

	if not hud then return end

	hud:Draw()
end

-- Paints player status HUD element in the bottom left
function GM:HUDPaint()
	local client = LocalPlayer()

	-- Perform Layout
	local scrW = ScrW()
	local scrH = ScrH()
	local changed = false

	if client.oldScrW and client.oldScrW ~= scrW and client.oldScrH and client.oldScrH ~= scrH then
		local hud = huds.GetStored(HUDManager.GetHUD())
		if hud then
			hud:Reset()
		end

		changed = true
	end

	if changed or not client.oldScrW or not client.oldScrH then
		client.oldScrW = scrW
		client.oldScrH = scrH
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTargetID") then
		hook.Call("HUDDrawTargetID", GAMEMODE)
	end

	HUDManager.DrawHUD()

	if not client:Alive() or client:Team() == TEAM_SPEC then return end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTRadar") then
		RADAR:Draw(client)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTTButton") then
		TBHUD:Draw(client)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTVoice") then
		VOICE.Draw(client)
	end

	if hook.Call("HUDShouldDraw", GAMEMODE, "TTTPickupHistory") then
		hook.Call("HUDDrawPickupHistory", GAMEMODE)
	end
end

-- Hide the standard HUD stuff
local hud = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true
}

function GM:HUDShouldDraw(name)
	if hud[name] then
		return false
	end

	return self.BaseClass.HUDShouldDraw(self, name)
end

local function UpdateHUD(name)
	local hudEl = huds.GetStored(name)

	if not hudEl then
		MsgN("Error: HUD with name " .. name .. " was not found!")
		return
	end

	HUDEditor.StopEditHUD()

	current_hud_cvar:SetString(name)

	-- Initialize elements
	hudEl:Initialize()

	hudEl:LoadData()
end

function HUDManager.GetHUD()
	local currentHUD = current_hud_cvar:GetString()
	local currentHUDTbl = huds.GetStored(currentHUD)

	if not currentHUDTbl then
		return HUDManager.defaultHUD
	end

	return currentHUD
end

function HUDManager.SetHUD(name)
	local currentHUD = HUDManager.GetHUD()

	net.Start("TTT2RequestHUD")
	net.WriteString(name or currentHUD)
	net.WriteString(currentHUD)
	net.SendToServer()
end

-- if forced or requested, modified by server restrictions
net.Receive("TTT2ReceiveHUD", function()
	UpdateHUD(net.ReadString())
end)
