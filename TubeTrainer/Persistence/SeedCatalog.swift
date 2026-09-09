import Foundation

/// The built-in, data-driven exercise catalog seeded on first launch.
/// Broad enough that a normal gym user is unlikely to hit a missing basic.
enum SeedCatalog {

    struct Seed {
        let name: String
        let category: MuscleCategory
        let equipment: Equipment
        let aliases: [String]
        var rest: Int = 90
    }

    static let exercises: [Seed] = [
        // Chest
        Seed(name: "Barbell Bench Press", category: .chest, equipment: .barbell, aliases: ["bench", "flat bench", "bench press"], rest: 150),
        Seed(name: "Dumbbell Bench Press", category: .chest, equipment: .dumbbell, aliases: ["db bench", "dumbbell press"]),
        Seed(name: "Incline Dumbbell Press", category: .chest, equipment: .dumbbell, aliases: ["incline db press", "incline press"]),
        Seed(name: "Incline Barbell Press", category: .chest, equipment: .barbell, aliases: ["incline bench"]),
        Seed(name: "Chest Press Machine", category: .chest, equipment: .machine, aliases: ["machine chest press"]),
        Seed(name: "Cable Fly", category: .chest, equipment: .cable, aliases: ["cable crossover", "chest fly", "pec fly"]),
        Seed(name: "Pec Deck", category: .chest, equipment: .machine, aliases: ["machine fly", "pec deck fly"]),
        Seed(name: "Push-Up", category: .chest, equipment: .bodyweight, aliases: ["pushup", "press up"], rest: 60),

        // Back
        Seed(name: "Pull-Up", category: .back, equipment: .bodyweight, aliases: ["pullup", "chin up"], rest: 120),
        Seed(name: "Lat Pulldown", category: .back, equipment: .cable, aliases: ["pulldown", "lat pull"]),
        Seed(name: "Barbell Row", category: .back, equipment: .barbell, aliases: ["bent over row", "bb row", "barbell bent row"], rest: 120),
        Seed(name: "Dumbbell Row", category: .back, equipment: .dumbbell, aliases: ["db row", "one arm row", "single arm row"]),
        Seed(name: "Seated Cable Row", category: .back, equipment: .cable, aliases: ["cable row", "seated row"]),
        Seed(name: "Chest-Supported Row", category: .back, equipment: .machine, aliases: ["t bar row", "machine row", "supported row"]),
        Seed(name: "Face Pull", category: .back, equipment: .cable, aliases: ["facepull", "rope face pull"], rest: 60),

        // Shoulders
        Seed(name: "Barbell Overhead Press", category: .shoulders, equipment: .barbell, aliases: ["ohp", "military press", "overhead press", "shoulder press", "standing press"], rest: 120),
        Seed(name: "Dumbbell Shoulder Press", category: .shoulders, equipment: .dumbbell, aliases: ["db shoulder press", "seated shoulder press", "shoulder press"]),
        Seed(name: "Machine Shoulder Press", category: .shoulders, equipment: .machine, aliases: ["machine press", "shoulder press machine", "shoulder press"]),
        Seed(name: "Lateral Raise", category: .shoulders, equipment: .dumbbell, aliases: ["side raise", "lat raise", "side delt raise"], rest: 60),
        Seed(name: "Rear Delt Fly", category: .shoulders, equipment: .dumbbell, aliases: ["reverse fly", "rear delt", "rear fly"], rest: 60),

        // Biceps
        Seed(name: "Barbell Curl", category: .biceps, equipment: .barbell, aliases: ["bb curl", "bicep curl"], rest: 60),
        Seed(name: "Dumbbell Curl", category: .biceps, equipment: .dumbbell, aliases: ["db curl", "bicep curl"], rest: 60),
        Seed(name: "Hammer Curl", category: .biceps, equipment: .dumbbell, aliases: ["hammer"], rest: 60),
        Seed(name: "Cable Curl", category: .biceps, equipment: .cable, aliases: ["cable bicep curl"], rest: 60),

        // Triceps
        Seed(name: "Triceps Pushdown", category: .triceps, equipment: .cable, aliases: ["tricep pushdown", "rope pushdown", "cable pushdown", "pushdown"], rest: 60),
        Seed(name: "Overhead Triceps Extension", category: .triceps, equipment: .cable, aliases: ["overhead extension", "tricep extension"], rest: 60),
        Seed(name: "Skull Crusher", category: .triceps, equipment: .barbell, aliases: ["lying tricep extension", "skullcrusher"], rest: 75),
        Seed(name: "Dip", category: .triceps, equipment: .bodyweight, aliases: ["dips", "tricep dip", "chest dip"], rest: 90),

        // Quadriceps
        Seed(name: "Back Squat", category: .quadriceps, equipment: .barbell, aliases: ["squat", "barbell squat"], rest: 180),
        Seed(name: "Front Squat", category: .quadriceps, equipment: .barbell, aliases: ["front barbell squat"], rest: 180),
        Seed(name: "Leg Press", category: .quadriceps, equipment: .machine, aliases: ["machine leg press"], rest: 150),
        Seed(name: "Hack Squat", category: .quadriceps, equipment: .machine, aliases: ["machine hack squat"], rest: 150),
        Seed(name: "Leg Extension", category: .quadriceps, equipment: .machine, aliases: ["leg extensions", "quad extension"], rest: 75),
        Seed(name: "Walking Lunge", category: .quadriceps, equipment: .dumbbell, aliases: ["lunges", "lunge", "walking lunges"]),
        Seed(name: "Bulgarian Split Squat", category: .quadriceps, equipment: .dumbbell, aliases: ["bss", "split squat", "rear foot elevated split squat"], rest: 120),

        // Hamstrings
        Seed(name: "Deadlift", category: .hamstrings, equipment: .barbell, aliases: ["conventional deadlift", "dl"], rest: 210),
        Seed(name: "Romanian Deadlift", category: .hamstrings, equipment: .barbell, aliases: ["rdl", "romanian dl", "stiff leg deadlift"], rest: 150),
        Seed(name: "Leg Curl", category: .hamstrings, equipment: .machine, aliases: ["hamstring curl", "lying leg curl", "seated leg curl"], rest: 75),

        // Glutes
        Seed(name: "Hip Thrust", category: .glutes, equipment: .barbell, aliases: ["barbell hip thrust", "glute bridge"], rest: 120),

        // Calves
        Seed(name: "Standing Calf Raise", category: .calves, equipment: .machine, aliases: ["calf raise", "standing calves"], rest: 60),
        Seed(name: "Seated Calf Raise", category: .calves, equipment: .machine, aliases: ["seated calves"], rest: 60),

        // Core
        Seed(name: "Plank", category: .core, equipment: .bodyweight, aliases: ["front plank"], rest: 45),
        Seed(name: "Hanging Leg Raise", category: .core, equipment: .bodyweight, aliases: ["leg raise", "hanging leg raises"], rest: 60),
        Seed(name: "Cable Crunch", category: .core, equipment: .cable, aliases: ["kneeling crunch", "rope crunch"], rest: 60),
        Seed(name: "Ab Wheel", category: .core, equipment: .other, aliases: ["ab rollout", "wheel rollout"], rest: 60),

        // Full body / conditioning
        Seed(name: "Kettlebell Swing", category: .fullBody, equipment: .kettlebell, aliases: ["kb swing", "swing"], rest: 60),
        Seed(name: "Clean and Press", category: .fullBody, equipment: .barbell, aliases: ["clean press"], rest: 150),

        // Cardio
        Seed(name: "Treadmill", category: .cardio, equipment: .machine, aliases: ["run", "running", "jog"], rest: 0),
        Seed(name: "Rowing Machine", category: .cardio, equipment: .machine, aliases: ["row erg", "erg", "rower"], rest: 0),
        Seed(name: "Stationary Bike", category: .cardio, equipment: .machine, aliases: ["bike", "cycling", "spin"], rest: 0),

        // Mobility / warm-up
        Seed(name: "Cat-Cow", category: .mobility, equipment: .bodyweight, aliases: ["cat cow", "spinal mobility"], rest: 0),
        Seed(name: "World's Greatest Stretch", category: .mobility, equipment: .bodyweight, aliases: ["wgs", "greatest stretch"], rest: 0),
        Seed(name: "Band Pull-Apart", category: .mobility, equipment: .band, aliases: ["pull apart", "band pullapart"], rest: 0),
    ]

    /// Recommended exercises per training structure, keyed by day name.
    /// Names must match seed names above.
    static func plan(for structure: TrainingStructure) -> [(day: String, exercises: [String])] {
        switch structure {
        case .fullBody:
            return [
                ("Full Body A", ["Back Squat", "Barbell Bench Press", "Barbell Row", "Dumbbell Shoulder Press", "Leg Curl", "Plank"]),
                ("Full Body B", ["Deadlift", "Incline Dumbbell Press", "Lat Pulldown", "Leg Press", "Lateral Raise", "Cable Crunch"]),
            ]
        case .upperLower:
            return [
                ("Upper", ["Barbell Bench Press", "Barbell Row", "Dumbbell Shoulder Press", "Lat Pulldown", "Dumbbell Curl", "Triceps Pushdown"]),
                ("Lower", ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Standing Calf Raise", "Hanging Leg Raise"]),
            ]
        case .pushPullLegs:
            return [
                ("Push Day", ["Barbell Bench Press", "Dumbbell Shoulder Press", "Incline Dumbbell Press", "Lateral Raise", "Triceps Pushdown", "Overhead Triceps Extension"]),
                ("Pull Day", ["Deadlift", "Pull-Up", "Barbell Row", "Seated Cable Row", "Face Pull", "Barbell Curl"]),
                ("Leg Day", ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Standing Calf Raise", "Hanging Leg Raise"]),
            ]
        case .bodyPart:
            return [
                ("Chest", ["Barbell Bench Press", "Incline Dumbbell Press", "Chest Press Machine", "Cable Fly", "Push-Up"]),
                ("Back", ["Pull-Up", "Barbell Row", "Lat Pulldown", "Seated Cable Row", "Face Pull"]),
                ("Shoulders", ["Barbell Overhead Press", "Dumbbell Shoulder Press", "Lateral Raise", "Rear Delt Fly", "Face Pull"]),
                ("Arms", ["Barbell Curl", "Hammer Curl", "Cable Curl", "Triceps Pushdown", "Skull Crusher"]),
                ("Legs", ["Back Squat", "Romanian Deadlift", "Leg Press", "Leg Extension", "Leg Curl", "Standing Calf Raise"]),
            ]
        case .custom:
            return [("My Workout", [])]
        }
    }
}
