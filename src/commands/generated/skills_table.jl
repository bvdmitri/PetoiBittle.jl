# Metadata table for the robot's built-in named skills (gaits, postures, behaviors).
#
# This file is DATA ONLY. The companion `skills_generator.jl` turns each row into a
# singleton `Command` type, its `serialize_to_bytes!` method, a convenience verb, the
# matching docstrings, and the public-API marking.
#
# Columns:
#   - `category`    : grouping used for docs ("Gaits" | "Postures" | "Behaviors").
#   - `julia_name`  : the generated `Command` subtype name (PascalCase). Accessed as
#                     `PetoiBittle.<julia_name>`.
#   - `verb`        : the generated convenience function name (snake_case). Accessed as
#                     `PetoiBittle.<verb>(connection)`.
#   - `token`       : the exact ASCII token the firmware expects. Sent verbatim, then
#                     newline-terminated by `send_command`.
#   - `description` : a short human-readable description used in the generated docstrings
#                     and the documentation overview table.
#
# `julia_name` and `verb` are kept as explicit columns (not derived from one another) so the
# user-facing names are reviewable and stable. Tokens are taken from the Petoi/OpenCat serial
# protocol; see https://docs.petoi.com/apis/serial-protocol.
#
# Note: the firmware's bare rest command `'d'` is exposed separately as
# [`PetoiBittle.Rest`](@ref) and is intentionally NOT duplicated here.
const NAMED_SKILLS = (
    # --- Gaits (continuous locomotion) ---
    (category = "Gaits", julia_name = :Stepping,       verb = :step_in_place,        token = "kvt",  description = "march in place without moving forward"),
    (category = "Gaits", julia_name = :Backward,       verb = :walk_backward,        token = "kbk",  description = "walk backward"),
    (category = "Gaits", julia_name = :BackwardLeft,   verb = :walk_backward_left,   token = "kbkL", description = "walk backward and to the left"),
    (category = "Gaits", julia_name = :BackwardRight,  verb = :walk_backward_right,  token = "kbkR", description = "walk backward and to the right"),
    (category = "Gaits", julia_name = :CrawlForward,   verb = :crawl_forward,        token = "kcrF", description = "crawl forward"),
    (category = "Gaits", julia_name = :CrawlLeft,      verb = :crawl_left,           token = "kcrL", description = "crawl forward and to the left"),
    (category = "Gaits", julia_name = :CrawlRight,     verb = :crawl_right,          token = "kcrR", description = "crawl forward and to the right"),
    (category = "Gaits", julia_name = :WalkForward,    verb = :walk_forward,         token = "kwkF", description = "walk forward"),
    (category = "Gaits", julia_name = :WalkLeft,       verb = :walk_left,            token = "kwkL", description = "walk forward and to the left"),
    (category = "Gaits", julia_name = :WalkRight,      verb = :walk_right,           token = "kwkR", description = "walk forward and to the right"),
    (category = "Gaits", julia_name = :TrotForward,    verb = :trot_forward,         token = "ktrF", description = "trot forward"),
    (category = "Gaits", julia_name = :TrotLeft,       verb = :trot_left,            token = "ktrL", description = "trot forward and to the left"),
    (category = "Gaits", julia_name = :TrotRight,      verb = :trot_right,           token = "ktrR", description = "trot forward and to the right"),
    (category = "Gaits", julia_name = :Bound,          verb = :bound_forward,        token = "kbdF", description = "bound forward"),

    # --- Postures (single-frame static poses) ---
    (category = "Postures", julia_name = :Balance,         verb = :balance,           token = "kbalance", description = "stand still and self-balance"),
    (category = "Postures", julia_name = :ButtUp,          verb = :butt_up,           token = "kbuttUp",  description = "raise the hindquarters (butt up)"),
    (category = "Postures", julia_name = :CalibrationPose, verb = :calibration_pose,  token = "kcalib",   description = "stand in the calibration pose"),
    (category = "Postures", julia_name = :Sit,             verb = :sit,               token = "ksit",     description = "sit down"),
    (category = "Postures", julia_name = :Sleep,           verb = :nap,               token = "ksleep",   description = "fold down into the sleep posture"),
    (category = "Postures", julia_name = :Stretch,         verb = :stretch,           token = "kstr",     description = "stretch the body"),
    (category = "Postures", julia_name = :Zero,            verb = :straighten,        token = "kzero",    description = "straighten all joints to the neutral (zero) pose"),

    # --- Behaviors (multi-frame one-shot actions) ---
    (category = "Behaviors", julia_name = :CheckAround, verb = :check_around, token = "kck",  description = "look around to check the surroundings"),
    (category = "Behaviors", julia_name = :Greeting,    verb = :greet,        token = "khi",  description = "greet with a friendly gesture"),
    (category = "Behaviors", julia_name = :Pee,         verb = :pee,          token = "kpee", description = "lift a leg to pee"),
    (category = "Behaviors", julia_name = :PushUp,      verb = :push_up,      token = "kpu",  description = "do push-ups"),
    (category = "Behaviors", julia_name = :MimicDeath,  verb = :play_dead,    token = "kpd",  description = "play dead (mimic death)"),
    (category = "Behaviors", julia_name = :BackFlip,    verb = :back_flip,    token = "kbf",  description = "perform a backflip")
)
