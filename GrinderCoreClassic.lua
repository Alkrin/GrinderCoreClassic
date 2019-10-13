--GrinderCoreClassic
--Written By Tiok - US Thrall

GRINDERCORECLASSIC_VERSION = 1.0
GCC_INITIALIZED = false

GrinderCoreClassic_AltBags = {};

function GrinderCoreClassic_OnLoad()
    GrinderCoreClassic_RegisterEvents();
end

function GrinderCoreClassic_RegisterEvents()
    GrinderCoreClassicFrame:RegisterEvent("VARIABLES_LOADED");
    GrinderCoreClassicFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
    GrinderCoreClassicFrame:RegisterEvent("BANKFRAME_OPENED");
    GrinderCoreClassicFrame:RegisterEvent("BAG_UPDATE");
end

function GrinderCoreClassic_OnEvent(frame, event, ...)
    if ( event == "VARIABLES_LOADED" ) then
        GrinderCoreClassic_Init();
    elseif( event == "BAG_UPDATE" ) then
        GrinderCoreClassic_UpdateItemCounts();
    elseif( event == "BANKFRAME_OPENED" ) then
        GrinderCoreClassic_UpdateItemCounts();
    elseif( event == "PLAYERBANKSLOTS_CHANGED" ) then
        GrinderCoreClassic_UpdateItemCounts();
    end
end

function GrinderCoreClassic_Init()
    GCC_INITIALIZED = true
    --Make sure the Settings variables exist.
    if(GrinderCoreClassic_Settings == nil)or(GrinderCoreClassic_Settings["Version"] == nil)or(GrinderCoreClassic_Settings["Version"] < GRINDERCORECLASSIC_VERSION)then
        GrinderCoreClassic_Settings = 
        {
            ["Version"] = GRINDERCORECLASSIC_VERSION,
            ["Item IDs"] = {},
            ["Item Tracked By"] = {}, --Key: Item Name, Value: set of factions
            ["Item Update For"] = {} --Key: faction, Value: T/F (set to true when any item for the given faction has changed count on this character)
        };

        GrinderCoreClassic_Inventories = nil;
    end

    --Make sure the Inventories variables exist.
    if(GrinderCoreClassic_Inventories == nil)then
        GrinderCoreClassic_Inventories = {}
    end
    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")] == nil) then
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")] = {}
    end
    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"] == nil) then
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"] = {}
    end
    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"] == nil) then
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"] = {}
    end
    if(GrinderCoreClassic_AltBags == nil) then
        GrinderCoreClassic_AltBags = {}
    end

    --Make sure there is an Inventories entry for the current character.
    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")] == nil)then
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")] = 
        {
            ["Carried"] = {},
            ["Total"] = {}
        }
    end

    --Make sure each bag for the current character has a value for every registered item.
    for _,itemID in ipairs(GrinderCoreClassic_Settings["Item IDs"]) do
        GrinderCoreClassic_AltBags[itemID] = 0;
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID] = GetItemCount(itemID,false);
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID] = GetItemCount(itemID,true);
    end

    --Calculate alt item totals here once so we never have to do it again.
    for RealmPlusName,_ in pairs(GrinderCoreClassic_Inventories) do
        local index = strfind(RealmPlusName, "_");
        local realm = strsub(RealmPlusName,1,index-1);
        local toonName = strsub(RealmPlusName,index+1,string.len(RealmPlusName));

        if((realm == GetRealmName()) and (toonName ~= UnitName("player")))then
            for itemName,itemId in pairs(GrinderCoreClassic_Settings["Item IDs"])do
                if(GrinderCoreClassic_Inventories[RealmPlusName]["Total"][itemId] == nil) then GrinderCoreClassic_Inventories[RealmPlusName]["Total"][itemId] = 0; end
                GrinderCoreClassic_AltBags[itemId] = GrinderCoreClassic_AltBags[itemId] + GrinderCoreClassic_Inventories[RealmPlusName]["Total"][itemId];
            end
        end
    end
    
    --Make sure the Factions variables exist.  sysTime = getServerTime()
    if(GrinderCoreClassic_Factions == nil)then
        GrinderCoreClassic_Factions = 
        {
            ["Rep Ground"] = {}; --Key: faction, Value: # of rep earned while grinding
            ["Grinding Time"] = {}; --Key: faction, Value: # of seconds spent grinding
        }
    end
end

function GrinderCoreClassic_UpdateItemCounts()
    if not (GCC_INITIALIZED) then return end
    for _,itemID in ipairs(GrinderCoreClassic_Settings["Item IDs"])do
        if(GetItemCount(itemID,false) ~= GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID])or
          (GetItemCount(itemID,true) ~= GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID])then
            GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID] = GetItemCount(itemID,false);
            GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID] = GetItemCount(itemID,true);
            for _,faction in pairs(GrinderCoreClassic_Settings["Item Tracked By"][itemID]) do
            	GrinderCoreClassic_Settings["Item Update For"][faction] = true;
            end
        end
    end
end

function GrinderCoreClassic_IDFromItemLink(link)
    local index = strfind(link, ":");
    if ( index ) then
        link = strsub(link, index+1, index+8);
        index = strfind(link,":");
        if(index) then
            link = strsub(link,1,index-1);
        else
            link = "";
        end
    else
        link = "";
    end	
    return link;
end

function GrinderCoreClassic_TableContainsValue(table,value)
    local result = false;
    for _,val in pairs(table) do
        if(value == val)then
            result = true;
            break;
        end
    end
    return result;
end

function GrinderCoreClassic_RegisterItem(faction,itemID)
    if not (GCC_INITIALIZED) then return end

    if (not GrinderCoreClassic_TableContainsValue(GrinderCoreClassic_Settings["Item IDs"],itemID))then
	    --This item has not previously been tracked, so set it up everywhere!
        table.insert(GrinderCoreClassic_Settings["Item IDs"],itemID)
        GrinderCoreClassic_Settings["Item Tracked By"][itemID] = {faction};
        GrinderCoreClassic_Settings["Item Update For"][faction] = false;
        GrinderCoreClassic_AltBags[itemID] = 0;
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID] = GetItemCount(itemID,false);
        GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID] = GetItemCount(itemID,true);
    elseif (not(GrinderCoreClassic_TableContainsValue(GrinderCoreClassic_Settings["Item Tracked By"][itemID],faction))) then
        --This item has been previously tracked, so make sure this addon is in the tracking list.
        table.insert(GrinderCoreClassic_Settings["Item Tracked By"][itemID],faction);
    end
end

function GrinderCoreClassic_PlayerInventoryCount(itemID)
    if not (GCC_INITIALIZED) then return end

    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID] == nil)then
        return 0
    else
        return GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Carried"][itemID]
    end
    return 0
end

function GrinderCoreClassic_PlayerTotalCount(itemID)
    if not (GCC_INITIALIZED) then return end

    if(GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID] == nil)then
        return 0
    else
        return GrinderCoreClassic_Inventories[GetRealmName().."_"..UnitName("player")]["Total"][itemID]
    end
    return 0
end

function GrinderCoreClassic_AltTotalCount(itemID)
    if(GrinderCoreClassic_AltBags[itemID] == nil)then
    	return 0
    else
        return GrinderCoreClassic_AltBags[itemID]
    end
    return 0
end

function GrinderCoreClassic_GetGrindingTime(faction)
    if not (GCC_INITIALIZED) then return end

    if(GrinderCoreClassic_Factions["Grinding Time"][faction] == nil)then
        return 0
    else
        return GrinderCoreClassic_Factions["Grinding Time"][faction];
    end
    return 0
end

function GrinderCoreClassic_SetGrindingTime(faction,seconds)
    if not (GCC_INITIALIZED) then return end

    GrinderCoreClassic_Factions["Grinding Time"][faction] = seconds;
end

function GrinderCoreClassic_GetRepGround(faction)
    if not (GCC_INITIALIZED) then return end

    if(GrinderCoreClassic_Factions["Rep Ground"][faction] == nil)then
        return 0
    else
        return GrinderCoreClassic_Factions["Rep Ground"][faction];
    end
    return 0
end

function GrinderCoreClassic_SetRepGround(faction,rep)
    if not (GCC_INITIALIZED) then return end

    GrinderCoreClassic_Factions["Rep Ground"][faction] = rep;
end

function GrinderCoreClassic_FactionItemsChanged(faction)
    if not (GCC_INITIALIZED) then return false end

    return GrinderCoreClassic_Settings["Item Update For"][faction];
end

function GrinderCoreClassic_AcknowledgeItemChange(faction)
    if not (GCC_INITIALIZED) then return end

    GrinderCoreClassic_Settings["Item Update For"][faction] = false;
end
