--No connected realms, so just the realm with mixed with the faction (like in
--the 8.2.0 edition of Logistician)
function Logistician.Variables.GetConnectedRealmRoot()
  return GetRealmName() .. " " .. (UnitFactionGroup("player"))
end
