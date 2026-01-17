local _, NS = ...

-- ===================================
-- Constants Module
-- All hardcoded values in one place
-- ===================================

local Constants = {}

-- === FONTS & STYLING ===
Constants.FONT_FACE = "Interface\\AddOns\\NeliMythicTimer\\Media\\Roboto.ttf"
Constants.FONT_FLAG = "OUTLINE"
Constants.BAR_TEXTURE = "Interface\\Buttons\\WHITE8x8"

-- Font Sizes
Constants.SIZE_HEADER = 14
Constants.SIZE_TIMER = 20
Constants.SIZE_UPGRADE = 14
Constants.SIZE_DEATH = 14
Constants.SIZE_AFFIX = 10
Constants.SIZE_BAR_TEXT = 12
Constants.SIZE_BOSS_LIST = 12
Constants.SIZE_NAMEPLATE = 10

-- === GAME CONSTANTS ===
Constants.DIFFICULTY_MYTHIC_PLUS = 8
Constants.TIMER_ID = 1

-- Death Penalties (in seconds)
Constants.DEATH_PENALTY_NONE = 0
Constants.DEATH_PENALTY_STANDARD = 5
Constants.DEATH_PENALTY_HIGH = 15

-- Key Level Thresholds
Constants.KEY_LEVEL_DEATH_TRACKING = 3
Constants.KEY_LEVEL_HIGH_PENALTY = 12

-- Timer Thresholds
Constants.THRESHOLD_TWO_CHEST = 0.8
Constants.THRESHOLD_THREE_CHEST = 0.6

-- === UI CONSTANTS ===
Constants.MAIN_FRAME_WIDTH = 285
Constants.MAIN_FRAME_HEIGHT = 300
Constants.ENEMY_BAR_WIDTH = 270
Constants.ENEMY_BAR_HEIGHT = 16
Constants.BOSS_CONTAINER_WIDTH = 230
Constants.BOSS_CONTAINER_HEIGHT = 200
Constants.BOSS_LINE_HEIGHT = 20

-- Colors
Constants.COLOR_GHOST_BAR = {r = 0, g = 1, b = 0, a = 0.4}
Constants.COLOR_ENEMY_BAR = {r = 0.45, g = 0, b = 0.85, a = 1}
Constants.COLOR_AFFIX_TEXT = {r = 0.5, g = 0.5, b = 0.5, a = 1}

-- === PULL TRACKER ===
Constants.PULL_EVENTS = {
    ["SPELL_DAMAGE"] = true,
    ["RANGE_DAMAGE"] = true,
    ["SWING_DAMAGE"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_PERIODIC_DAMAGE"] = true,
}

NS.Constants = Constants
