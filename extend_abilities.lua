local ALL_ABILITY_EXCEPTIONS = LoadKeyValues('scripts/npc/ability_exceptions.txt')

--- Generally Useful stuff

function CDOTABaseAbility:ParentOverrideCurrentGesture( ENUM_GESTURE )
  if self:GetCaster().currentGesture then
    self:GetCaster():RemoveGesture( self:GetCaster().currentGesture )
  end
  self:GetCaster().currentGesture = ENUM_GESTURE
	self:GetCaster():StartGesture( ENUM_GESTURE )
end

function CDOTABaseAbility:ApplyDamageToEnemiesWithin( v_location, radius, dmg_amount, dmg_type )
  -- print("Damaging Enemies in given area")
	-- when we start the spell, look for units (heroes and creeps) nearby, and deal damage
	local units = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), v_location, self:GetCaster(), radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )

	for u,unit in pairs(units) do
		-- the damage parameter for each unit
		local table = {
						victim = unit,
						attacker = self:GetCaster(),
						damage = dmg_amount,
						damage_type = dmg_type,
						damage_flags = 0,
						ability = self
					}
		ApplyDamage( table )
	end
end

function CDOTABaseAbility:FindClosestBasicEnemyWithin( radius )
  -- print("Finding closest Enemy with radius")
  -- when we start the spell, look for units (heroes and creeps) nearby, and deal damage
  local units = FindUnitsInRadius(
    self:GetCaster():GetTeamNumber(),
    self:GetCaster():GetOrigin(),
    self:GetCaster(),
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    0,
    FIND_CLOSEST,
    false
  )
  return units[1]
end

function CDOTABaseAbility:FindBasicEnemiesWithin( targetPos, radius )
  -- print("Finding basic Enemies within radius")
  -- when we start the spell, look for units (heroes and creeps) nearby, and deal damage
  local units = FindUnitsInRadius(
    self:GetCaster():GetTeamNumber(),
    targetPos,
    self:GetCaster(),
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    0,
    FIND_ANY_ORDER,
    false
  )
  return units
end

function CDOTABaseAbility:CreateIndicator( v_location, fl_duration, fl_radius ) -- creates a particle and places it at a particular location with a particular radius
  local pfx_name = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown_ring.vpcf" -- used as the ground indicator for snapfire's ult
  -- print("Creating Indicator")
  local pfx = ParticleManager:CreateParticle( pfx_name, PATTACH_POINT, self:GetCaster() )
  if not self.orbitals then
    self.orbitals = {}
  end
  ParticleManager:SetParticleControl( pfx, 0, v_location )
  ParticleManager:SetParticleControl( pfx, 1, Vector( fl_radius,0,0 ) )
  ParticleManager:SetParticleControl( pfx, 2, Vector( fl_duration,0,0 ) )
  -- print("Created Indicator!!!")
end

function CDOTABaseAbility:GetRandomPointInRadius( v_location, min_dist, max_dist )
  local random_length = RandomInt( min_dist, max_dist )
  local random_point = v_location + RandomVector( random_length )
  return random_point
end

function CDOTABaseAbility:GetRandomPointInSquare( v_location, min_dist, max_dist )
  local x_range = RandomInt( min_dist, max_dist )
  local y_range = RandomInt( min_dist, max_dist )
  local chance_x_positive = RandomInt(1,2)
  local chance_Y_positive = RandomInt(1,2)

  if chance_x_positive==1 then x_range = -x_range end
  if chance_Y_positive==1 then y_range = -y_range end
  v_location.x = v_location.x + x_range
  v_location.y = v_location.y + y_range

  return v_new_location
end

function CDOTABaseAbility:IsAMapAbility() -- checks whether this ability is an ability unique to map interactions
  local name = self:GetName()
  if name=="ability_lamp_use" or name=="ability_capture" or name=="ability_pluck_famango" or name== "twin_gate_portal_warp" or name=="abyssal_underlord_portal_warp" then
    return true
  end
  return false
end

function CDOTABaseAbility:IsAMainAbility()
  local name = self:GetName()
  if not self:IsAMapAbility() and name~="generic_hidden" and not string.match( name, "talent" ) and not string.match( name, "bonus" ) then
    return true
  else
    return false
  end
end

function CDOTABaseAbility:GetAllAbilitySpecials() -- Gets the USEFUL ability special values ONLY
  local specialsArray = {}

  local abilityKeys = self:GetAbilityKeyValues()
  local abilitySpecials = abilityKeys["AbilitySpecial"]

  if abilitySpecials==nil then
    abilitySpecials = abilityKeys["AbilityValues"]
    local isTalent = string.match( self:GetName(), "special_bonus")
    if abilitySpecials and not isTalent then

      -- DeepPrint( abilitySpecials )

      for k,v in pairs( abilitySpecials ) do

        local isVarType = string.match( k, "var_type")
        local isScepterCheck = string.match( k, "scepter")
        local isTooltipCal = string.match( k, "Calculate")
        local isTalentStuff = string.match( k, "LinkedSpecialBonus")
        -- local vIsTable = type(k)=="table"

        if isVarType or isScepterCheck or isTooltipCal or isTalentStuff then
          -- print( "key is not useful" )
        -- elseif vIsTable then
          
        else
          table.insert( specialsArray, k )
        end

      end
    end

  else
    local isTalent = string.match( self:GetName(), "special_bonus")
    if abilitySpecials and not isTalent then

      -- DeepPrint( abilitySpecials )

      for k,v in pairs( abilitySpecials ) do
        for x,y in pairs(v) do

          local isVarType = string.match( x, "var_type")
          local isScepterCheck = string.match( x, "scepter")
          local isTooltipCal = string.match( x, "Calculate")
          local isTalentStuff = string.match( x, "LinkedSpecialBonus")

          if isVarType or isScepterCheck or isTooltipCal or isTalentStuff then
            -- print(key is not useful)
          else
            table.insert(specialsArray,x)
          end

        end
      end
    end

  end

  if abilitySpecials==nil then
    -- print( "Error ocurred. No ability specials found for ", self:GetName() )
    return {}
  end

  return specialsArray
end

function CDOTABaseAbility:GetHasAbilitySpecialWith( name_str ) -- checks whether an ability has a special value containing this string in the name
  local specialsArray = self:GetAllAbilitySpecials()

  for i=1,#specialsArray do
    if string.match( specialsArray[i], name_str ) then
      return true
    end
  end

  return false
end

function CDOTABaseAbility:GetFirstAbilitySpecialNameContaining( name_str ) -- checks whether an ability has a special value containing this string in the name
  local specialsArray = self:GetAllAbilitySpecials()

  for i=1,#specialsArray do
    if string.match( specialsArray[i], name_str ) then
      return specialsArray[i]
    end
  end

  return false
end

function CDOTABaseAbility:GetCastTypeString()
  local abilityKeys = self:GetAbilityKeyValues()
  local abilityBehavior = abilityKeys["AbilityBehavior"]
  return abilityBehavior
end

function CDOTABaseAbility:GetReturnReleaseOrEndAbilityName()
  
  local name = self:GetName()
  local secondary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    secondary_name = ALL_ABILITY_EXCEPTIONS[name].has_secondary
  end

  if secondary_name~=nil then
    return secondary_name
  end

  return nil
end

function CDOTABaseAbility:IsReturnReleaseOrEndAbilityName()
  
  local name = self:GetName()

  local primary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    primary_name = ALL_ABILITY_EXCEPTIONS[name].has_primary
  end

  if primary_name~=nil then
    return primary_name
  else
    return false
  end
end


--- Subcast Library Stuff

function CDOTABaseAbility:BeginCastStormRadial( ability_name, origin, cast_qty, delay, min_dist, max_dist, min_radius, max_radius, b_randomize_origin )

  if IsClient() then return end

  self.last_casters = {}

  local hero = self:GetCaster()
  local subcasters = hero:GetIdleSubcasters()

  self.pos = {}

  for i=1,cast_qty do

    self.pos[i] = self:GetRandomPointInRadius( origin, min_dist, max_dist )
    local unit = subcasters[i]

    if unit~=nil then
      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.radius = RandomInt( 10*min_radius, 10*max_radius ) / 10
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      end

      local original_ability = hero:FindAbilityByName(ability_name)
      if original_ability then
        ability:SetLevel( original_ability:GetLevel() )
      else
        ability:SetLevel( self:GetLevel() )
      end
      ability:EndCooldown()

      local abilityBehavior = ability:GetCastTypeString()
      local cast_type = nil
      
      if string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      ability:SetLevel( self:GetLevel() )
      if cast_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local caster_new_pos = self:GetCaster():GetAbsOrigin()
        unit:SetAbsOrigin(caster_new_pos)
      end
      local secondary_position = self:GetRandomPointInRadius( self.pos[i], 1, 200 )

      if b_randomize_origin then
        unit:SetAbsOrigin( self:GetRandomPointInRadius( self.pos[i], 50, 300 ) )
        secondary_position = self:GetCaster():GetAbsOrigin()
      end
      
      if string.match( abilityBehavior, "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then

        local order_params = {
          UnitIndex = unit:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
          AbilityIndex = ability:GetEntityIndex(),
          TargetIndex = unit:GetEntityIndex(),
          Position = secondary_position,
          Queue = false
        }
        unit:DelayCastWithOrders( order_params, 0 )

        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
      end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = ability:GetEntityIndex(),
        Position = self.pos[i],
        Queue = false
      }

      unit:DelayCastWithOrders( order_params, delay*i )
      self.last_casters = {}
      table.insert( self.last_casters, unit )

      Timers:CreateTimer( delay + 1, function()
        ability:EndCooldown()
        return nil
      end)
    end

  end
end

--     SplitSubcast(
--       ability_name, -- spellname string for the ability the subcaster(s) should cast
--       origin, -- position at which to place the subcasters
--       original_angles, -- orientation of the hero when the spell was originally cast
--       cast_qty, -- # of times to cast / number of subcasters
--       delay, -- Time/Seconds between each cast
--       angle_increment_degrees, -- rotate next subcaster by x degrees around the chosen origin, 1x per cast_qty
--       offset_angle_degrees, -- give all subcasters a base rotation of x degrees around the chosen 'origin' position
--       dist_from_origin, -- place subcasters this distance ahead of the origin, in the direction the caster was facing
--       dist_from_subcaster, -- subcasters cast spell x distance ahead of themselves ()
--       dist_increment, -- move the subcasters forward by x distance, incrementally each cast
--       radius_fl, -- multiply the radius of the ability being cast. 1=normal
--       damage_fl, -- multiply the damage of the ability being cast
--       length_int, -- set the exact 'length' kv for the ability. If nil then it uses default length
--       vector_cast_rotation ) -- rotate vector-cast abilities by x degrees

function CDOTABaseAbility:SplitSubcast( ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, length_int, vector_cast_rotation )

  if IsClient() then return end

  local hero = self:GetCaster()
  local subcasters = hero:GetIdleSubcasters( hero )
  
  --------------
  -- Start logic for secondary abilities
  --------------

  local original_ability = hero:FindAbilityByName(ability_name)
  local has_secondary = false
  local is_secondary = false

  if origin==nil or origin==Vector(0,0,0) then
    origin = hero:GetAbsOrigin()
  end

  if original_ability~=nil then
    has_secondary = original_ability:GetReturnReleaseOrEndAbilityName()~=nil
    is_secondary = original_ability:IsReturnReleaseOrEndAbilityName()
  end

  if original_ability~=nil and has_secondary then
    local secondary_ability_name = original_ability:GetReturnReleaseOrEndAbilityName()
    local secondary_ability = hero:FindAbilityByName( secondary_ability_name )

    local current_prepped = secondary_ability.prepped_casters
    
    if secondary_ability.prepped_casters==nil then
      secondary_ability.prepped_casters = subcasters
    else
      for i=1,cast_qty do
        local num_in_prepped = #current_prepped
        secondary_ability.prepped_casters[ num_in_prepped + i ] = subcasters[i]
      end
    end
  end

  if is_secondary and original_ability~=nil and original_ability.prepped_casters~=nil then -- if the original ability is a secondary ability and has prepared casters, then use those casters

    local previous_casters = original_ability.prepped_casters

    for i=1,#previous_casters do
      subcasters[i] = original_ability.prepped_casters[i]
    end

    cast_qty = #previous_casters
    origin = hero:GetAbsOrigin()
    -- original_ability.prepped_casters = {}
  end

  --------------
  -- End Secondary Ability Logic
  --------------

  for i=1,cast_qty do
    local unit = subcasters[i]

    -- if unit==nil then return end
    if unit ~= nil then
      unit:SetAbsOrigin( origin )
      -- unit.busy = true
      local angle_mult = i - 1 -- times to increment the angle, starting at 0 for the first iteration
      
      local y_degrees = offset_angle_degrees + ( angle_increment_degrees * angle_mult )
      local rotation = QAngle( 0, y_degrees, 0 )

      local random_degrees = vector_cast_rotation + ( angle_increment_degrees * angle_mult )
      local random_vector_rotation = QAngle( 0, random_degrees, 0 )
      -- local rand_rot_pos = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )

      local cast_type = DOTA_UNIT_ORDER_CAST_POSITION

      local new_forward = RotateOrientation( rotation, original_angles )
      local rand_vector_forward = RotateOrientation( random_vector_rotation, original_angles )

      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.damage = damage_fl
      weak_abil.radius = radius_fl
      weak_abil.length = length_int

      -- print(unit)
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      else
        ability:EndCooldown()
      end

      if original_ability then
        ability:SetLevel( original_ability:GetLevel() )
      else
        print( "Did not find original of named ability. Setting level to equal to 'self' level instead (usually 1).")
        ability:SetLevel( self:GetLevel() )
      end

      ability:SetHidden(false)
      local abilityBehavior = ability:GetCastTypeString()
      -- abilityEndCooldown()

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      local pos_1 = origin + ( unit:GetForwardVector() * ( dist_from_origin + ( dist_increment * i ) ) ) -- get incremented distance from origin at designated angle
      local pos_1_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at

      unit:SetAbsAngles( 0, rand_vector_forward.y, 0 )
      local pos_2 = pos_1_cast
      local pos_2_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at
      -- local radius = abilityGetSpecialValueFor(radius)
      
      if string.match( abilityBehavior, "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then

        local order_params = {
          UnitIndex = unit:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
          AbilityIndex = ability:GetEntityIndex(),
          TargetIndex = unit:GetEntityIndex(),
          Position = pos_1_cast,
          Queue = false
        }
        unit:DelayCastWithOrders( order_params, 0 )

        cast_type = DOTA_UNIT_ORDER_CAST_POSITION

      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
        unit:SetAbsOrigin( origin )
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      -- local subcaster_origin_spun = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      -- local subcaster_origin = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )
      -- local cast_pos = unitGetAbsOrigin() + ( unitGetForwardVector()  dist_from_subcaster )

      local cast_pos = nil
      -- if isVTarget_b then
      if vector_cast_rotation~=nil and vector_cast_rotation~=0 then -- should cast from pos_2, targeting pos_2_cast
        unit:SetAbsOrigin( pos_2 )
        cast_pos = pos_2_cast
      else
        unit:SetAbsOrigin( pos_1 )
        cast_pos = pos_1_cast
      end
      -- end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = unit:GetEntityIndex(),
        Position = cast_pos,
        Queue = false
      }

      unit:DelayCastWithOrders( order_params, delay*i )
      unit.busy = true

      Timers:CreateTimer( delay+4, function()
        ability:EndCooldown()
        unit.busy = false
        return nil
      end)
    end
  end
end


---- SOME SUBCAST EXAMPLES


  -- "flower" pattern -- casts your spell in 3-5 rows, 3-4 casts long. Usually curved
  --   for i=1,5 do
  --     Timers:CreateTimer( 0.4*i, function()
  --       self:SplitSubcast( spellName, self:GetOrigin(), self:GetAngles(), 5, 0, 360/5, 0, 1, 110*i, 0, 0.6*i, 1, nil, nil )
  --       self.RemoveSelf = true
  --       return nil
  --     end)
  --   end


  -- "echo" pattern -- casts your spell 4 times in the same location with growing size  
  --   for i=1,4 do
  --     Timers:CreateTimer( 1.4*(i-1), function()
  --       self:SplitSubcast( spellName, self:GetOrigin(), self:GetAngles(), 1, 1, 1, 1, 1, 1, 0, 0.7*i, 1, nil, 0 )
  --     end)
  --   end


  -- "wave" pattern -- cast your ability in a wave in front of you
  --   local spread = 45
  --   for i=1,4 do
  --     Timers:CreateTimer( 0.4*i, function()
  --       self:SplitSubcast( spellName, self:GetOrigin(), self:GetAngles(), 1+i, 0, spread/i, -spread/2, 200*i, 100*i, 0, 1+(0.5*i), 1, nil, 0 )
  --       self.RemoveSelf = true
  --       return nil
  --     end)
  --   end


  -- "spiral" pattern
  --     for i=1,20 do
  --       Timers:CreateTimer( 0.1*i, function()
  --         local progression = 180 + (600/(10+i/2)*i)*posNeg
  --         self:SplitSubcast( spellName, self:GetOrigin(), self:GetAngles(), 1, 0, 0, progression, 45*i, 100, 0, 0.2 + 0.2*i, 0.5, nil, progression+90 )
  --         self.RemoveSelf = true
  --         return nil
  --       end)
  --     end


  -- "pentagram" pattern -- instantly cast your ability in a single ring around you, angled into a pentagram.
  --   local star_points = RandomInt( 5, 8 )
  --   self:SplitSubcast( spellName, self:GetOrigin(), self:GetAngles(), star_points, 0, 360/star_points, 0, 250, 250, 0, 1, 1, 250, 180 + 180/star_points )