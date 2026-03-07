import Foundation

// MARK: - Exercise Content Data
// Passages and questions for all 4 difficulty levels

struct Passage: Identifiable {
    let id: String
    let title: String
    let text: String
    let level: DifficultyLevel
    let mcqQuestions: [MCQQuestion]
    let vocabularyPairs: [VocabPair]
    let fillBlanks: [FillBlank]
    let fluencyText: String   // simplified version for speaking
}

struct MCQQuestion: Identifiable {
    let id: String = UUID().uuidString
    let question: String
    let options: [String]
    let correctIndex: Int
}

struct VocabPair: Identifiable {
    let id: String = UUID().uuidString
    let word: String
    let meaning: String
}

struct FillBlank: Identifiable {
    let id: String = UUID().uuidString
    let sentence: String        // sentence with "___" placeholder
    let answer: String
    let hint: String
}

// MARK: - Content Library
struct ContentLibrary {
    static let passages: [Passage] = [
        beginnerPassage,
        intermediatePassage,
        advancedPassage,
        proPassage
    ]

    static func passage(for level: DifficultyLevel) -> Passage {
        passages.first(where: { $0.level == level }) ?? beginnerPassage
    }
}

// MARK: - Beginner Passage
let beginnerPassage = Passage(
    id: "beg_1",
    title: "The Helpful Dog",
    text: """
Max was a golden dog who lived with a kind family. Every morning, Max would wake up early and bring the newspaper to his owner, Tom. Tom always smiled and gave Max a treat. One rainy day, Max found a small lost kitten near the garden. Max barked softly and led Tom to the kitten. Tom brought the kitten inside and gave it warm milk. From that day, Max and the kitten became best friends. They played in the garden every afternoon and slept together every night.
""",
    level: .beginner,
    mcqQuestions: [
        MCQQuestion(question: "What is Max?", options: ["A cat", "A golden dog", "A bird", "A rabbit"], correctIndex: 1),
        MCQQuestion(question: "What did Max bring every morning?", options: ["Milk", "Toys", "The newspaper", "Shoes"], correctIndex: 2),
        MCQQuestion(question: "What did Tom give Max after bringing the newspaper?", options: ["A hug", "A treat", "Water", "A ball"], correctIndex: 1),
        MCQQuestion(question: "Where did Max find the kitten?", options: ["In the house", "Near the garden", "On the street", "In a tree"], correctIndex: 1),
        MCQQuestion(question: "What happened to the kitten?", options: ["It ran away", "Tom gave it warm milk", "Max ate it", "It slept outside"], correctIndex: 1)
    ],
    vocabularyPairs: [
        VocabPair(word: "Golden", meaning: "Having a bright yellow colour"),
        VocabPair(word: "Treat", meaning: "A special small reward"),
        VocabPair(word: "Lost", meaning: "Unable to find the way"),
        VocabPair(word: "Softly", meaning: "In a quiet and gentle way"),
        VocabPair(word: "Afternoon", meaning: "The time between noon and evening")
    ],
    fillBlanks: [
        FillBlank(sentence: "Max was a ___ dog.", answer: "golden", hint: "Color of the sun"),
        FillBlank(sentence: "Tom always gave Max a ___ after the newspaper.", answer: "treat", hint: "Small reward"),
        FillBlank(sentence: "Max found a small lost ___ near the garden.", answer: "kitten", hint: "Baby cat"),
        FillBlank(sentence: "Max ___ softly to call Tom.", answer: "barked", hint: "Sound a dog makes"),
        FillBlank(sentence: "Tom brought the kitten inside and gave it warm ___.", answer: "milk", hint: "White drink from cows")
    ],
    fluencyText: "Max was a golden dog. He lived with a kind family. Every morning Max brought the newspaper. One day he found a lost kitten. Tom gave the kitten warm milk."
)

// MARK: - Intermediate Passage
let intermediatePassage = Passage(
    id: "int_1",
    title: "The River Village",
    text: """
The village of Sapphire Creek rested beside a sparkling river that wound through a dense forest. The villagers depended on the river for drinking water, fishing, and farming. Every spring, the river flooded its banks slightly, depositing rich soil that made crops grow abundantly. The children loved to swim in the calmer parts during summer, while elders sat on the banks telling stories of ancient times. A wise woman named Mara taught the children to respect the river, warning that if they polluted it, the fish would disappear. One dry summer, a factory upstream began releasing waste, and within weeks the river turned murky. Remembering Mara's words, the children led a cleanup effort that restored the river's clarity.
""",
    level: .intermediate,
    mcqQuestions: [
        MCQQuestion(question: "What was the name of the village?", options: ["Crystal Creek", "Sapphire Creek", "Silver River", "Blue Lake"], correctIndex: 1),
        MCQQuestion(question: "How did the spring floods help the village?", options: ["They provided fresh water", "They deposited rich soil", "They brought fish", "They cleaned the village"], correctIndex: 1),
        MCQQuestion(question: "What did Mara warn the children about?", options: ["Swimming too deep", "Polluting the river", "Cutting the forest", "Staying out late"], correctIndex: 1),
        MCQQuestion(question: "What happened because of the factory upstream?", options: ["The village flooded", "The river turned murky", "Fish grew bigger", "The forest caught fire"], correctIndex: 1),
        MCQQuestion(question: "Who led the cleanup effort?", options: ["Mara", "The elders", "The children", "The factory workers"], correctIndex: 2)
    ],
    vocabularyPairs: [
        VocabPair(word: "Abundantly", meaning: "In large or plentiful amounts"),
        VocabPair(word: "Depositing", meaning: "Laying down or placing something"),
        VocabPair(word: "Murky", meaning: "Dark and dirty, not clear"),
        VocabPair(word: "Ancient", meaning: "Very old, belonging to the past"),
        VocabPair(word: "Clarity", meaning: "The quality of being clear and transparent")
    ],
    fillBlanks: [
        FillBlank(sentence: "The village of ___ Creek rested beside a sparkling river.", answer: "Sapphire", hint: "A precious blue gemstone"),
        FillBlank(sentence: "The spring floods deposited rich ___ for farming.", answer: "soil", hint: "Earth in which plants grow"),
        FillBlank(sentence: "A wise woman named ___ taught the children.", answer: "Mara", hint: "The wise woman's name"),
        FillBlank(sentence: "A factory upstream began releasing ___.", answer: "waste", hint: "Harmful unwanted material"),
        FillBlank(sentence: "The children led a ___ effort that restored the river.", answer: "cleanup", hint: "Removing dirt and pollution")
    ],
    fluencyText: "The village of Sapphire Creek was beside a river. The river helped the villagers with water and farming. A wise woman named Mara taught the children to protect the river. When a factory polluted it, the children cleaned it up."
)

// MARK: - Advanced Passage
let advancedPassage = Passage(
    id: "adv_1",
    title: "The Language of Stars",
    text: """
For centuries, astronomers have decoded the language of stars by analyzing the light they emit. Each star produces a unique spectrum of colours when its light passes through a prism — a phenomenon known as spectroscopy. By studying these spectral lines, scientists can determine a star's temperature, chemical composition, velocity, and even its distance from Earth. For instance, hydrogen produces a signature pattern of red, blue-green, and violet lines. Helium was first discovered not on Earth but in the sun's spectrum before scientists found it terrestrially. The Doppler effect explains how stars moving away from us appear redder — their light waves stretch — while those approaching appear bluer. This elegant cosmic language has allowed humanity to understand galaxies billions of light-years away without ever travelling there.
""",
    level: .advanced,
    mcqQuestions: [
        MCQQuestion(question: "What is spectroscopy?", options: ["Studying planets", "Analyzing light spectra from stars", "Measuring star distances by radar", "Observing black holes"], correctIndex: 1),
        MCQQuestion(question: "Where was helium first discovered?", options: ["On Earth in a laboratory", "In a meteor", "In the sun's spectrum", "On Mars"], correctIndex: 2),
        MCQQuestion(question: "What does the Doppler effect explain about stars moving away?", options: ["They appear brighter", "Their light appears redder", "They grow larger", "They emit less light"], correctIndex: 1),
        MCQQuestion(question: "What information can spectral lines provide about a star?", options: ["Its name and age only", "Temperature, composition, velocity, distance", "Size and weight only", "Whether it has planets"], correctIndex: 1),
        MCQQuestion(question: "What happens to light waves from stars moving toward us?", options: ["They stretch and appear red", "They compress and appear bluer", "They disappear", "They become invisible"], correctIndex: 1)
    ],
    vocabularyPairs: [
        VocabPair(word: "Spectrum", meaning: "A range of colours or wavelengths of light"),
        VocabPair(word: "Terrestrially", meaning: "On or relating to the Earth"),
        VocabPair(word: "Composition", meaning: "The elements or parts that make up something"),
        VocabPair(word: "Phenomenon", meaning: "A remarkable or observable fact or event"),
        VocabPair(word: "Velocity", meaning: "The speed of something in a given direction")
    ],
    fillBlanks: [
        FillBlank(sentence: "Analyzing star light through a prism is called ___.", answer: "spectroscopy", hint: "The science of light spectra"),
        FillBlank(sentence: "Helium was first discovered in the sun's ___ before being found on Earth.", answer: "spectrum", hint: "Range of light wavelengths"),
        FillBlank(sentence: "Stars moving away from us appear ___.", answer: "redder", hint: "Opposite end of spectrum from blue"),
        FillBlank(sentence: "The ___ effect explains the colour shift of moving stars.", answer: "Doppler", hint: "Named after a physicist"),
        FillBlank(sentence: "Hydrogen produces signature ___ lines in the spectrum.", answer: "spectral", hint: "Relating to the spectrum")
    ],
    fluencyText: "Astronomers study the light from stars using spectroscopy. Each star has a unique spectrum. Helium was discovered in the sun before it was found on Earth. Stars moving away appear redder due to the Doppler effect."
)

// MARK: - Pro Passage
let proPassage = Passage(
    id: "pro_1",
    title: "Neuroplasticity and Learning",
    text: """
Neuroplasticity — the brain's remarkable capacity to reorganize itself by forming new neural connections throughout life — fundamentally challenges the outdated notion that our brains are fixed, immutable structures after childhood. Contemporary neuroscience reveals that every experience, skill acquired, or habit developed physically alters the brain's architecture. Synaptic pruning, the process by which unused connections are eliminated during adolescence, optimizes neural efficiency but also underscores the critical importance of enriched learning environments during developmental years. Conversely, enriched environments stimulate dendritic growth, strengthening the pathways between neurons. Research by Maguire et al. demonstrated that London taxi drivers exhibited measurably enlarged hippocampi — a region associated with spatial navigation — compared to non-drivers. This exemplifies experience-dependent plasticity: the brain literally reshapes itself in response to sustained cognitive demands, offering profound implications for rehabilitative medicine, education, and our understanding of human potential.
""",
    level: .pro,
    mcqQuestions: [
        MCQQuestion(question: "What does neuroplasticity refer to?", options: ["Brain size increase with age", "The brain's ability to form new neural connections", "Memory loss in adults", "Genetic brain coding"], correctIndex: 1),
        MCQQuestion(question: "What is synaptic pruning?", options: ["Growing new neurons", "Eliminating unused neural connections", "Strengthening all synapses", "Repairing damaged brain tissue"], correctIndex: 1),
        MCQQuestion(question: "What did Maguire et al. find about London taxi drivers?", options: ["They had faster reaction times", "They had enlarged hippocampi", "They had better eyesight", "They showed reduced anxiety"], correctIndex: 1),
        MCQQuestion(question: "What does dendritic growth do?", options: ["Weakens neural pathways", "Strengthens pathways between neurons", "Removes old memories", "Reduces brain activity"], correctIndex: 1),
        MCQQuestion(question: "What outdated notion does neuroplasticity challenge?", options: ["That the brain can learn", "That brains are fixed structures after childhood", "That neurons exist", "That learning takes effort"], correctIndex: 1)
    ],
    vocabularyPairs: [
        VocabPair(word: "Neuroplasticity", meaning: "The brain's ability to reorganize by forming new connections"),
        VocabPair(word: "Immutable", meaning: "Unchanging over time; permanent"),
        VocabPair(word: "Synaptic", meaning: "Relating to the junction between nerve cells"),
        VocabPair(word: "Hippocampi", meaning: "Brain regions associated with memory and navigation"),
        VocabPair(word: "Rehabilitative", meaning: "Relating to the restoration of health or normal life")
    ],
    fillBlanks: [
        FillBlank(sentence: "___ is the brain's capacity to reorganize by forming new connections.", answer: "Neuroplasticity", hint: "The main topic of the passage"),
        FillBlank(sentence: "Synaptic ___ eliminates unused connections during adolescence.", answer: "pruning", hint: "Like cutting branches from a tree"),
        FillBlank(sentence: "Taxi drivers had enlarged ___ compared to non-drivers.", answer: "hippocampi", hint: "Brain region for navigation"),
        FillBlank(sentence: "Enriched environments stimulate ___ growth.", answer: "dendritic", hint: "Branch-like extensions of neurons"),
        FillBlank(sentence: "Experience-dependent plasticity means the brain ___ itself in response to demands.", answer: "reshapes", hint: "Changes form")
    ],
    fluencyText: "Neuroplasticity means the brain can form new connections throughout life. Synaptic pruning removes unused connections during adolescence. London taxi drivers had larger hippocampi than non-drivers. The brain reshapes itself based on experience."
)

// MARK: - Exercise Items for Library/Journey
struct ExerciseItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String
    var category: ExerciseCategory
    var difficulty: Int   // 1–9 sub-levels within the 4 main levels
    var durationMinutes: Int
    var isCompleted: Bool = false
}

struct ContentLibraryData {
    static func exercises(for level: DifficultyLevel, category: ExerciseCategory) -> [ExerciseItem] {
        let base = level.rawValue
        let prefix = "\(level.label) \(category.rawValue)"
        return [
            ExerciseItem(title: "\(prefix) – Session 1", description: "Practice \(category.rawValue.lowercased()) with guided exercises.", category: category, difficulty: base, durationMinutes: 5),
            ExerciseItem(title: "\(prefix) – Session 2", description: "Strengthen your \(category.rawValue.lowercased()) skills.", category: category, difficulty: base, durationMinutes: 7),
            ExerciseItem(title: "\(prefix) – Session 3", description: "Challenge yourself with varied \(category.rawValue.lowercased()) tasks.", category: category, difficulty: base + 1, durationMinutes: 8),
            ExerciseItem(title: "\(prefix) – Session 4", description: "Advanced \(category.rawValue.lowercased()) practice.", category: category, difficulty: base + 2, durationMinutes: 10),
            ExerciseItem(title: "\(prefix) – Session 5", description: "Master \(category.rawValue.lowercased()) at your level.", category: category, difficulty: base + 2, durationMinutes: 12),
        ]
    }
}
