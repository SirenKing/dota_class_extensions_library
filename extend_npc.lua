-- LinkLuaModifier( "modifier_bonus_drop_chance", "modifiers/modifier_bonus_drop_chance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_animation_override", "extend_npc", LUA_MODIFIER_MOTION_NONE )

function CDOTA_BaseNPC:PlaySequenceWithRateModifier( act, seq_str, rate, dur )

  local mod = nil

  if self:HasModifier("modifier_animation_override") then
    self:RemoveModifierByName("modifier_animation_override")
  end

  mod = self:AddNewModifier( nil, nil, "modifier_animation_override", { duration = dur } )

  mod.rate = rate
  mod.act = act
  mod.sequence_string = seq_str
  mod.dur = dur
  mod:ForceRefresh()

  return mod
end

function CDOTA_BaseNPC:GetDropLuck()
  local luck = 0
  if self:HasModifier("modifier_bonus_drop_chance") then
		luck = self:FindModifierByName("modifier_bonus_drop_chance"):GetStackCount()
  else
    self:AddNewModifier( self, nil, "modifier_bonus_drop_chance", {} )
	end
  return luck
end

function CDOTA_BaseNPC:SetDropLuck( luck )
  if self:HasModifier("modifier_bonus_drop_chance") then
		self:FindModifierByName("modifier_bonus_drop_chance"):SetStackCount( luck )
  else
    self:AddNewModifier( self, nil, "modifier_bonus_drop_chance", {} )
	end
end

function CDOTA_BaseNPC:MaybeDropItem( killer, luck_bonus )
  local rand_100 = RandomInt(1,100)

  local common_min = 100 - BUTTINGS.COMMON_CHANCE
  local uncommon_min = 100 - BUTTINGS.UNCOMMON_CHANCE
  local rare_min = 100 - BUTTINGS.RARE_CHANCE
  local legend_min = 100 - BUTTINGS.LEGENDARY_CHANCE
  local item = nil

  if rand_100 >= legend_min then
    item = self:DropItemRewardForHero( killer, "legendary" )
  else
    if rand_100 >= rare_min then
      item = self:DropItemRewardForHero( killer, "rare" )
    else
      if rand_100 >= uncommon_min then
        item = self:DropItemRewardForHero( killer, "uncommon" )
      else
        if rand_100 >= ( common_min + luck_bonus ) then
          item = self:DropItemRewardForHero( killer, "common" )
        else
          if BUTTINGS.ENCHANTS_DEBUG then
            print("KILLS_DROP_ITEMS_DEBUG: dropped nothing")
          end
        end
      end
    end
  end
  return item
end

function CDOTA_BaseNPC:DropItemRewardForHero( killer, rarity_str )
  if BUTTINGS.ENCHANTS_DEBUG then
    print("KILLS_DROP_ITEMS_DEBUG: dropped ", rarity_str, " item")
  end
  local pos = self:GetAbsOrigin()
  local item_table = DROPS[ rarity_str ]
  local item_name = item_table[ RandomInt( 1, #item_table ) ]
  local item = CreateItem( item_name, killer, nil )
  CreateItemOnPositionSync( pos, item )
  item:LaunchLootInitialHeight( false, 0, 100, 0.75, pos)
  return item
end

function CDOTA_BaseNPC:CreateSubcasters( num )
  self.subcasters = {}
  for i=1,num do
    local unit = CreateUnitByName( "npc_dota_subcaster", self:GetOrigin(), false, self, nil, self:GetTeam() )
    -- if unit:HasAbility("hidden_underfoot") then
    --   unit:FindAbilityByName("hidden_underfoot"):SetLevel(1)
    -- end
    -- unit:SetOwner( self )
    unit.hero_parent = self
    -- for i=1,24 do
    --   local test_ability = self:GetAbilityByIndex(i)
    --   if test_ability:GetName() then
        
    --   end
    -- end

    self.subcasters[i] = unit
    self.subcasters[i].busy = false
    unit.busy = false
  end
  
  SUBCASTERS = self.subcasters
  print( "Hero " .. self:GetName() .. " has " .. #SUBCASTERS .. " subcasters ")

  return self.subcasters
end

function CDOTA_BaseNPC:GetSubcasters()
  return self.subcasters
end

function CDOTA_BaseNPC:GetIdleSubcasters()
  local subcs = self.subcasters
  local idle = {}
  local add_shard = self:HasModifier( "modifier_item_aghanims_shard" )
  local add_scepter = self:HasModifier( "modifier_item_ultimate_scepter" ) or self:HasModifier( "modifier_item_ultimate_scepter_consumed" )

  if subcs==nil then
    subcs = self:CreateSubcasters( 21 )
  end

  for i=1,#subcs do
    local has_scepter = subcs[i]:HasModifier( "modifier_item_ultimate_scepter_consumed" ) or subcs[i]:HasModifier( "modifier_item_ultimate_scepter" )

    if add_shard and not subcs[i]:HasModifier("modifier_item_aghanims_shard") then
      subcs[i]:AddNewModifier( self, nil, "modifier_item_aghanims_shard", { duration = nil } )
    end

    if add_scepter and not has_scepter then
      subcs[i]:AddNewModifier( self, nil, "modifier_item_ultimate_scepter_consumed", { duration = 0 } )
    end

    if not subcs[i]:IsChanneling() and not subcs[i].busy then
      -- subcs[i]:Stop()
      subcs[i]:SetMana(600)
      table.insert( idle, subcs[i] )
      -- return subcs[i]
    end
  end

  return idle
end

function CDOTA_BaseNPC:DelayCastWithOrders( order_params, delay )
  order_params.UnitIndex = self:GetEntityIndex()

  Timers:CreateTimer( delay, function()

    ExecuteOrderFromTable( order_params )

    return nil
  end)
  
end

function CDOTA_BaseNPC:SetRandomForward()
  -- self:SetAbsAngles( 0, RandomVector(100).y, 0 ) -- needs to be tested
end

function CDOTA_BaseNPC:GetDistToPos( pos )
  local pos2 = self:GetAbsOrigin()
  local dx = pos.x - pos2.x
  local dy = pos.y - pos2.y
  local distanceToEnt = math.sqrt ( dx * dx + dy * dy )
  return distanceToEnt
end

function CDOTA_BaseNPC:GetMainHeroAbilities()

  local return_table = {}

  for i=0,30 do
    local ability = self:GetAbilityByIndex(i)
    if ability and ability:IsMainHeroAbility() then -- checks whether this ability is an ability that the hero uses, excluding abilities for map interaction
      table.insert( return_table, ability )
    end
  end

  return return_table
end