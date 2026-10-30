const path = require("@std/path")
--[[

iac allows for infrastructure as code. this supports defining a limited subset of the game as a luau file

iac.create_new_experience(experience): ExperienceResult
iac.update_experience(experience, old_experience_result): ExperienceResult

]]

export type Owner = {
	read kind: "community" | "user",
	id: number,
}

export type PlayableDevice = "desktop" | "mobile" | "tablet" | "console" | "vr"

export type Purchases = {}

export type PaidAccess = {
	robux: number,
}

export type PrivateServers = {
	robux: number,
} | true

export type AvatarType = "R6" | "R15" | "player_choice"
export type AvatarAnimationType = "standard" | "player_choice"
export type AvatarCollisionType = "outer_box" | "inner_box"

export type ScaleConstraints = {
	min: number?,
	max: number?,
}

export type AvatarScaleConstraints = {
	height: ScaleConstraints?,
	body_type: ScaleConstraints?,
	head: ScaleConstraints?,
	proportions: ScaleConstraints?,
	width: ScaleConstraints?,
}

export type AvatarAssetOverrides = {
	face: number?,
	head: number?,
	left_arm: number?,
	right_arm: number?,
	torso: number?,
	left_leg: number?,
	right_leg: number?,
	shirt: number?,
	pants: number?,
	tshirt: number?,
}

export type ServerFill = "roblox_optimized" | "maximum" | { reversed_slots: number }

export type SocialLink = {
	title: string,
	uri: string,
}

export type Place = {
	name: string?,
	root: boolean,

	description: string?,
	max_player_count: number,

	allow_copying: boolean?,
	server_fill: ServerFill?,
}

export type DeveloperProduct = {
	name: string,
	description: string,
	icon: path.Pathlike,
	robux_price: number?,
	managed_pricing: boolean?,
}

export type Gamepass = {
	name: string,
	description: string,
	icon: path.Pathlike,
	robux_price: number?,
	managed_pricing: boolean?,
}

export type Badge = {
	name: string,
	description: string,
	icon: path.Pathlike,
	enabled: boolean?,
}

export type SpatialVoice = {
	enabled: boolean,
}

export type Range = { min: number, max: number }

export type AvatarRules = {
	read avatar_type: AvatarType,
	read enable_sound: boolean?,
	read enable_vfx: boolean?,

	read overwrite_animations: {
		read jump: number?,
		read run: number?,
		read idle: number?,
		read climb: number?,
		read idle_alt1: number?,
		read idle_alt2: number?,
		read swim_idle: number?,
		read swim: number?,
		read walk: number?,
		read fall: number?,
	} | "player_choice" | "standard"?,

	read overwrite_clothing: {
		-- layered clothing
		read jacket: number?,
		read shirt: number?,
		read tshirt: number?,
		read sweater: number?,
		read dressskirt: number?,
		read pants: number?,
		read shorts: number?,
		read left_shoes: number?,
		read right_shoes: number?,

		read classic_tshirt: number?,
		read classic_shirt: number?,
		read classic_pants: number?,

		-- Removes or scales clothing that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
		read limit_bounds: false | { number }?,
	} | "player_choice"?,

	read overwrite_accessories: {
		read back: number?,
		read face: number?,
		read front: number?,
		read hair: number?,
		read head: number?,
		read neck: number?,
		read shoulder: number?,
		read waist: number?,

		-- Removes or scales accessories that exceeds the limit bounds. Limit bounds are based on a % of padding around the avatar.
		read limit_bounds: false | { number },
		read limit_method: "delete" | "downscale",
	} | "player_choice"?,

	read collision_mode: "legacy" | "outerbox" | "single_collider"?,
	read hit_and_touch_detection: "avatar_geometry" | "collider"?,
	read single_collider_size: { number }?,

	read overwrite_body: {
		read limit_body_type_scale: Range?, -- 0 to 1
		read limit_head_scale: Range?,
		read limit_height_scale: Range?,
		read limit_proportions_scale: Range?,
		read limit_width_scale: Range?,

		read scale_mode: "player_choice" | "forced"?,
		read forced_height_size: Range?,

		read allow_custom_bodyparts: boolean?,
		read keep_player_head: boolean?,
	}?,
}

--stylua: ignore
export type Experience = {
	read name: string?,
	read description: string?,
	read public: boolean?,

	read owner: Owner,
	read genre: string,

	read playable_device: { read [PlayableDevice]: true },
	read paid_access: PaidAccess?,
	read private_servers: PrivateServers?,

	read enable_studio_access_to_apis: boolean?,
	read allow_third_party_sales: boolean?,
	read allow_third_party_teleports: boolean?,

	-- read engine_avatar_settings: EngineAvatarSettings,

	-- read avatar_type: AvatarType,
	-- read avatar_animation_type: AvatarAnimationType?,
	-- read avatar_collision_type: AvatarCollisionType?,
	-- read avatar_scale_constraints: AvatarScaleConstraints?,
	-- read avatar_asset_overrides: AvatarAssetOverrides?,
	read avatar_rules: AvatarRules,

	read places: { [string]: Place },

	read social_links: { SocialLink }?,

	read products: { [string]: DeveloperProduct }?,
	read gamepasses: { [string]: Gamepass }?,
	read badges: { [string]: Badge }?,

	read spatial_voice: SpatialVoice?,
}

-- not defining allat :snore:
export type EngineAvatarSettings = typeof({
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
})

export type Hashes = { [string]: string }

export type ExperienceResult = {
	version: number,
	template: Experience?,

	universe_id: number?,
	root_place_id: number,
	place_ids: { [string]: number? },

	products: { [string]: number? },
	product_icons: Hashes,
	gamepasses: { [string]: number? },
	gamepass_icons: Hashes,
	badges: { [string]: number? },
	badge_icons: Hashes,
}

return nil
