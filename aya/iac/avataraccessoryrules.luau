const types = require("./types")

const function to_engine_avatar_settings(experience: types.Experience): types.EngineAvatarSettings
	const default: types.EngineAvatarSettings = {
		AvatarAnimationRules = {
			CustomJumpAnimationEnabled = false,
			CustomJumpAnimationId = 0,
			CustomRunAnimationEnabled = false,
			CustomRunAnimationId = 0,
			CustomIdleAnimationEnabled = false,
			CustomIdleAnimationId = 0,
			CustomClimbAnimationEnabled = false,
			CustomClimbAnimationId = 0,
			CustomIdleAlt1AnimationEnabled = false,
			CustomIdleAlt1AnimationId = 0,
			CustomIdleAlt2AnimationEnabled = false,
			CustomIdleAlt2AnimationId = 0,
			CustomSwimIdleAnimationEnabled = false,
			CustomSwimIdleAnimationId = 0,
			CustomSwimAnimationEnabled = false,
			CustomSwimAnimationId = 0,
			CustomWalkAnimationEnabled = false,
			CustomWalkAnimationId = 0,
			CustomFallAnimationEnabled = false,
			CustomFallAnimationId = 0,
			AnimationClipsMode = 0, -- Determines if custom animation clips are enabled. 0 = player choice, 1 = custom clips.
			AnimationPacksMode = 0, -- Determines a preset animation pack. 0 = player choice, 1 = standard R15, 2 = Standard R6.
		},
		AvatarClothingRules = {
			CustomJacketAccessoryEnabled = false,
			CustomJacketAccessoryId = 0,
			CustomShirtAccessoryEnabled = false,
			CustomShirtAccessoryId = 0,
			CustomTShirtAccessoryEnabled = false,
			CustomTShirtAccessoryId = 0,
			CustomSweaterAccessoryEnabled = false,
			CustomSweaterAccessoryId = 0,
			CustomDressSkirtAccessoryEnabled = false,
			CustomDressSkirtAccessoryId = 0,
			CustomPantsAccessoryEnabled = false,
			CustomPantsAccessoryId = 0,
			CustomShortsAccessoryEnabled = false,
			CustomShortsAccessoryId = 0,
			CustomLeftShoesAccessoryEnabled = false,
			CustomLeftShoesAccessoryId = 0,
			CustomRightShoesAccessoryEnabled = false,
			CustomRightShoesAccessoryId = 0,
			CustomClassicShirtsAccessoryEnabled = false,
			CustomClassicShirtsAccessoryId = 0,
			CustomClassicTShirtsAccessoryEnabled = false,
			CustomClassicTShirtsAccessoryId = 0,
			CustomClassicPantsAccessoryEnabled = false,
			CustomClassicPantsAccessoryId = 0,
			CustomClothingMode = 0, -- Determines if player's clothing is replaced with custom clothing. 0 = Player choice, 1 = custom clothing.
			ClothingMode = 0, -- Determines whether or not the clothing `LimitBounds` setting is used. 0 = no limit bounds, 1 = limit bounds.
			LimitBounds = { 0, 0, 0 }, -- Removes or scales clothing that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
		},
		AvatarAccessoryRules = {
			EnableSound = true,
			EnableVFX = true,
			CustomAccessoryMode = 0, -- Determines if player's clothing is replaced with custom clothing. 0 = Player choice, 1 = custom clothing.
			AccessoryMode = 0, -- Determines whether or not the accessory `LimitBounds` setting is used. 0 = no limit bounds, 1 = limit bounds.
			LimitMethod = 1, -- Determines if accessories that exceed the limit bounds are removed or scaled down. 0 = scaled down, 1 = removed.
			LimitBounds = { 0, 0, 0 }, -- Removes or scales accessories that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
			CustomBackAccessoryEnabled = false,
			CustomBackAccessoryId = 0,
			CustomFaceAccessoryEnabled = false,
			CustomFaceAccessoryId = 0,
			CustomFrontAccessoryEnabled = false,
			CustomFrontAccessoryId = 0,
			CustomHairAccessoryEnabled = false,
			CustomHairAccessoryId = 0,
			CustomHeadAccessoryEnabled = false,
			CustomHeadAccessoryId = 0,
			CustomNeckAccessoryEnabled = false,
			CustomNeckAccessoryId = 0,
			CustomShoulderAccessoryEnabled = false,
			CustomShoulderAccessoryId = 0,
			CustomWaistAccessoryEnabled = false,
			CustomWaistAccessoryId = 0,
		},
		AvatarCollisionRules = {
			CollisionMode = 1, -- Determines the type of collision avatars will have by default. 0 = "Default" / outerbox, 1 = "Single Collider", 2 = "Legacy" / innerbox.
			HitAndTouchDetectionMode = 0, -- Determines if colliders or avatar geometry is used for touch events. 0 = avatar geometry, 1 = colliders.
			LegacyCollisionMode = 1, --! Unknown what this does. It's always set to a value of 1.
			SingleColliderSize = { 2, 3, 1 }, -- Determines the size of the collider used if CollisionMode is set to single collider.
		},
		AvatarBodyRules = {
			BuildMode = 0, -- Determines whether or not avatars are forced to a specific, non-uniform scale. 0 = player choice, 1 = forced rigid scale.
			CustomBodyTypeScale = { 0, 0 }, -- Sets the min & max "rthro" scale for avatars. Valid value ranges are 0 through 1.
			CustomHeadScale = { 1, 1 }, -- Sets the min & max scale that avatar heads can have if BuildMode is set to forced scale. Valid value ranges are 0 through 1.
			CustomHeightScale = { 1, 1 }, -- Controls the min & max height that avatars can be if BuildMode is set to forced scale. Valid value ranges are 0 through 1.
			CustomProportionsScale = { 1, 1 }, -- Sets the min & max proportion scales for avatars. Valid value ranges are 0 through 1.
			CustomWidthScale = { 1, 1 }, -- Controls the min & max width that avatars can be if BuiildMode is set to forced scale. Valid value ranges are 0 through 1.
			ScaleMode = 1, -- Determines whether or not avatars are uniformly scaled to a certain height. 0 = player choice, 1 = forced height.
			CustomHeight = { 5.5, 5.5 }, -- Controls the min & max height (in studs) that avatars can be if ScaleMode is set to forced height.
			AppearanceMode = 0, -- Determines whether or not player avatars have custom body parts. 0 = player choice, 1 = custom body parts.
			KeepPlayerHead = true,
			CustomBodyType = 0,
			CustomBodyBundleId = 0,
			CustomEyebrowEnabled = false,
			CustomEyebrowId = 0,
			CustomEyelashEnabled = false,
			CustomEyelashId = 0,
			CustomFaceEnabled = false,
			CustomFaceId = 0,
			CustomHeadEnabled = false,
			CustomHeadId = 0,
			CustomLeftArmEnabled = false,
			CustomLeftArmId = 0,
			CustomLeftLegEnabled = false,
			CustomLeftLegId = 0,
			CustomMoodEnabled = false,
			CustomMoodId = 0,
			CustomRightArmEnabled = false,
			CustomRightArmId = 0,
			CustomRightLegEnabled = false,
			CustomRightLegId = 0,
			CustomTorsoEnabled = false,
			CustomTorsoId = 0,
		},
		AvatarRules = {
			AvatarType = 1, -- Determines whether R6, R15, or both rig types are allowed. 0 = R6, 1 = R15, 2 = R6 & R15.
		},
		version = 1, -- The current schema version of the avatar settings.
	}

	const rules = experience.avatar_rules

	default.AvatarRules.AvatarType = if rules.avatar_type == "R6"
		then 0
		elseif rules.avatar_type == "R15" then 1
		elseif rules.avatar_type == "player_choice" then 2
		else 1

	const animation_rules = rules.overwrite_animations

	if animation_rules == "player_choice" then
		default.AvatarAnimationRules.AnimationClipsMode = 0
		default.AvatarAnimationRules.AnimationPacksMode = if rules.avatar_type == "R6" then 2 else 0
	elseif animation_rules == "standard" or animation_rules == nil then
	else
		default.AvatarAnimationRules.CustomJumpAnimationEnabled = not not animation_rules.jump
		default.AvatarAnimationRules.CustomRunAnimationEnabled = not not animation_rules.run
		default.AvatarAnimationRules.CustomIdleAnimationEnabled = not not animation_rules.idle
		default.AvatarAnimationRules.CustomClimbAnimationEnabled = not not animation_rules.climb
		default.AvatarAnimationRules.CustomIdleAlt1AnimationEnabled = not not animation_rules.idle_alt1
		default.AvatarAnimationRules.CustomIdleAlt2AnimationEnabled = not not animation_rules.idle_alt2
		default.AvatarAnimationRules.CustomSwimIdleAnimationEnabled = not not animation_rules.swim_idle
		default.AvatarAnimationRules.CustomSwimAnimationEnabled = not not animation_rules.swim
		default.AvatarAnimationRules.CustomWalkAnimationEnabled = not not animation_rules.walk
		default.AvatarAnimationRules.CustomFallAnimationEnabled = not not animation_rules.fall

		default.AvatarAnimationRules.CustomJumpAnimationId = animation_rules.jump or 0
		default.AvatarAnimationRules.CustomRunAnimationId = animation_rules.run or 0
		default.AvatarAnimationRules.CustomIdleAnimationId = animation_rules.idle or 0
		default.AvatarAnimationRules.CustomClimbAnimationId = animation_rules.climb or 0
		default.AvatarAnimationRules.CustomIdleAlt1AnimationId = animation_rules.idle_alt1 or 0
		default.AvatarAnimationRules.CustomIdleAlt2AnimationId = animation_rules.idle_alt2 or 0
		default.AvatarAnimationRules.CustomSwimIdleAnimationId = animation_rules.swim_idle or 0
		default.AvatarAnimationRules.CustomSwimAnimationId = animation_rules.swim or 0
		default.AvatarAnimationRules.CustomWalkAnimationId = animation_rules.walk or 0
		default.AvatarAnimationRules.CustomFallAnimationId = animation_rules.fall or 0

		default.AvatarAnimationRules.AnimationClipsMode = if animation_rules.jump
				or animation_rules.run
				or animation_rules.idle
				or animation_rules.climb
				or animation_rules.idle_alt1
				or animation_rules.idle_alt2
				or animation_rules.swim_idle
				or animation_rules.swim
				or animation_rules.walk
				or animation_rules.fall
			then 1
			else 0
	end

	const clothing_rules = rules.overwrite_clothing

	if clothing_rules == "player_choice" or clothing_rules == nil then
		default.AvatarClothingRules.CustomClothingMode = 0
		default.AvatarClothingRules.ClothingMode = 0
	else
		-- sigh
		default.AvatarClothingRules.CustomJacketAccessoryEnabled = not not clothing_rules.jacket
		default.AvatarClothingRules.CustomShirtAccessoryEnabled = not not clothing_rules.shirt
		default.AvatarClothingRules.CustomTShirtAccessoryEnabled = not not clothing_rules.tshirt
		default.AvatarClothingRules.CustomSweaterAccessoryEnabled = not not clothing_rules.sweater
		default.AvatarClothingRules.CustomDressSkirtAccessoryEnabled = not not clothing_rules.dressskirt
		default.AvatarClothingRules.CustomPantsAccessoryEnabled = not not clothing_rules.pants
		default.AvatarClothingRules.CustomShortsAccessoryEnabled = not not clothing_rules.shorts
		default.AvatarClothingRules.CustomLeftShoesAccessoryEnabled = not not clothing_rules.left_shoes
		default.AvatarClothingRules.CustomRightShoesAccessoryEnabled = not not clothing_rules.right_shoes

		default.AvatarClothingRules.CustomClassicTShirtsAccessoryEnabled = not not clothing_rules.classic_tshirt
		default.AvatarClothingRules.CustomClassicShirtsAccessoryEnabled = not not clothing_rules.classic_shirt
		default.AvatarClothingRules.CustomClassicPantsAccessoryEnabled = not not clothing_rules.classic_pants

		default.AvatarClothingRules.CustomJacketAccessoryId = clothing_rules.jacket or 0
		default.AvatarClothingRules.CustomShirtAccessoryId = clothing_rules.shirt or 0
		default.AvatarClothingRules.CustomTShirtAccessoryId = clothing_rules.tshirt or 0
		default.AvatarClothingRules.CustomSweaterAccessoryId = clothing_rules.sweater or 0
		default.AvatarClothingRules.CustomDressSkirtAccessoryId = clothing_rules.dressskirt or 0
		default.AvatarClothingRules.CustomPantsAccessoryId = clothing_rules.pants or 0
		default.AvatarClothingRules.CustomShortsAccessoryId = clothing_rules.shorts or 0
		default.AvatarClothingRules.CustomLeftShoesAccessoryId = clothing_rules.left_shoes or 0
		default.AvatarClothingRules.CustomRightShoesAccessoryId = clothing_rules.right_shoes or 0

		default.AvatarClothingRules.CustomClassicTShirtsAccessoryId = clothing_rules.classic_tshirt or 0
		default.AvatarClothingRules.CustomClassicShirtsAccessoryId = clothing_rules.classic_shirt or 0
		default.AvatarClothingRules.CustomClassicPantsAccessoryId = clothing_rules.classic_pants or 0

		default.AvatarClothingRules.CustomClothingMode = if clothing_rules.jacket
				or clothing_rules.shirt
				or clothing_rules.tshirt
				or clothing_rules.sweater
				or clothing_rules.dressskirt
				or clothing_rules.pants
				or clothing_rules.shorts
				or clothing_rules.left_shoes
				or clothing_rules.right_shoes
				or clothing_rules.classic_tshirt
				or clothing_rules.classic_shirt
				or clothing_rules.classic_pants
			then 1
			else 0
		default.AvatarClothingRules.LimitBounds = if clothing_rules.limit_bounds
			then clothing_rules.limit_bounds
			else { 0, 0, 0 }
		default.AvatarClothingRules.ClothingMode = if clothing_rules.limit_bounds then 1 else 0
	end

	const accessory_rules = rules.overwrite_accessories

	default.AvatarAccessoryRules.EnableSound = rules.enable_sound or false
	default.AvatarAccessoryRules.EnableVFX = rules.enable_vfx or false

	if accessory_rules == "player_choice" or accessory_rules == nil then
		default.AvatarAccessoryRules.CustomAccessoryMode = 0
		default.AvatarAccessoryRules.AccessoryMode = 0
	else
		default.AvatarAccessoryRules.CustomBackAccessoryEnabled = not not accessory_rules.back
		default.AvatarAccessoryRules.CustomFaceAccessoryEnabled = not not accessory_rules.face
		default.AvatarAccessoryRules.CustomFrontAccessoryEnabled = not not accessory_rules.front
		default.AvatarAccessoryRules.CustomHairAccessoryEnabled = not not accessory_rules.hair
		default.AvatarAccessoryRules.CustomHeadAccessoryEnabled = not not accessory_rules.head
		default.AvatarAccessoryRules.CustomNeckAccessoryEnabled = not not accessory_rules.neck
		default.AvatarAccessoryRules.CustomShoulderAccessoryEnabled = not not accessory_rules.shoulder
		default.AvatarAccessoryRules.CustomWaistAccessoryEnabled = not not accessory_rules.waist

		default.AvatarAccessoryRules.CustomBackAccessoryId = accessory_rules.back or 0
		default.AvatarAccessoryRules.CustomFaceAccessoryId = accessory_rules.face or 0
		default.AvatarAccessoryRules.CustomFrontAccessoryId = accessory_rules.front or 0
		default.AvatarAccessoryRules.CustomHairAccessoryId = accessory_rules.hair or 0
		default.AvatarAccessoryRules.CustomHeadAccessoryId = accessory_rules.head or 0
		default.AvatarAccessoryRules.CustomNeckAccessoryId = accessory_rules.neck or 0
		default.AvatarAccessoryRules.CustomShoulderAccessoryId = accessory_rules.shoulder or 0
		default.AvatarAccessoryRules.CustomWaistAccessoryId = accessory_rules.waist or 0

		default.AvatarAccessoryRules.LimitMethod = if accessory_rules.limit_method == "delete" then 1 else 0
		default.AvatarAccessoryRules.LimitBounds = if accessory_rules.limit_bounds
			then accessory_rules.limit_bounds
			else { 0, 0, 0 }
		default.AvatarAccessoryRules.AccessoryMode = if accessory_rules.limit_bounds then 1 else 0
	end

	default.AvatarCollisionRules.CollisionMode = if rules.collision_mode == "legacy"
		then 2
		elseif rules.collision_mode == "outerbox" then 0
		elseif rules.collision_mode == "single_collider" then 1
		else 0
	default.AvatarCollisionRules.HitAndTouchDetectionMode = if rules.hit_and_touch_detection == "avatar_geometry"
		then 0
		elseif rules.hit_and_touch_detection == "collider" then 1
		else 0
	default.AvatarCollisionRules.SingleColliderSize = rules.single_collider_size or { 2, 3, 1 }

	const body_rules = rules.overwrite_body

	if body_rules == nil then
	else
		default.AvatarBodyRules.CustomBodyTypeScale = to_range(body_rules.limit_body_type_scale) or { 0, 1 }
		default.AvatarBodyRules.CustomHeadScale = to_range(body_rules.limit_head_scale) or { 0, 1 }
		default.AvatarBodyRules.CustomHeightScale = to_range(body_rules.limit_height_scale) or { 0, 1 }
		default.AvatarBodyRules.CustomProportionsScale = to_range(body_rules.limit_proportions_scale) or { 0, 1 }
		default.AvatarBodyRules.CustomWidthScale = to_range(body_rules.limit_width_scale) or { 0, 1 }

		default.AvatarBodyRules.CustomHeight = to_range(body_rules.forced_height_size) or { 5.5, 5.5 }
		default.AvatarBodyRules.ScaleMode = if body_rules.forced_height_size then 1 else 0

		default.AvatarBodyRules.AppearanceMode = if body_rules.allow_custom_bodyparts then 0 else 1
		default.AvatarBodyRules.KeepPlayerHead = if body_rules.keep_player_head == nil
			then true
			else body_rules.keep_player_head
	end

	return default
end

return {
	to_engine_avatar_settings = to_engine_avatar_settings,
}
