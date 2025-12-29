import Foundation
import SwiftUI

class OpenAIService {
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // Retrieve API Key from UserDefaults
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }
    
    enum AIError: Error {
        case missingApiKey
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct OpenAIRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
    }
    
    struct OpenAIResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
        }
    }
    
    func generateWorkoutPlan(
        durationMinutes: Int,
        preferences: [DrillPreference],
        recentPlans: [WorkoutPlan],
        focus: TrainingFocus
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingApiKey
        }
        
        let systemPrompt = "Du bist ein erfahrener Karate-Sensei im Wado-Ryu Karatestil, der Trainingseinheiten für Kinder und Jugendliche (8-16 Jahre) plant. Erstelle detaillierte, strukturierte Trainingspläne."
        
        var userPrompt = "Erstelle einen Karate-Trainingsplan für \(durationMinutes) Minuten mit Schwerpunkt \(focus.rawValue).\n"
        
        // Add Preferences
        let favorites = preferences.filter { $0.type == .favorite }.map { 
            $0.details.isEmpty ? $0.name : "\($0.name) (\($0.details))"
        }
        let blacklist = preferences.filter { $0.type == .blacklist }.map { 
            $0.details.isEmpty ? $0.name : "\($0.name) (\($0.details))"
        }
        
        if !favorites.isEmpty {
            userPrompt += "Versuche folgende Übungen einzubauen (wenn sinnvoll): \(favorites.joined(separator: ", ")).\n"
        }
        
        if !blacklist.isEmpty {
            userPrompt += "Vermeide unbedingt folgende Übungen: \(blacklist.joined(separator: ", ")).\n"
        }
        
        // Intelligent Progression from recent plans
        if !recentPlans.isEmpty {
            let lastTopics = recentPlans.prefix(3).map { $0.content }.joined(separator: " ... ")
            userPrompt += """
            Die letzten Trainingseinheiten waren:
            \(lastTopics)
            
            WICHTIG: Baue auf diesen Themen auf, aber biete Variationen an. Wiederhole nicht exakt das Gleiche, sondern entwickle die Übungen weiter (z.B. andere Partnerübungen, höhere Komplexität).
            """
        }
        
        userPrompt += """
        
        Struktur (EXAKT einhalten):
        1. Aufwärmen (Warm-up)
        2. Hauptteil (Main Part) - Schwerpunkt: \(focus.rawValue)
        3. Schluss (End Part) - KEIN Cool-down
        
        Formatierung:
        - KEINE Metadaten wie Datum oder Dauer in der Ausgabe.
        - Nutze Markdown für Überschriften (#, ##) und Fettungen (**), aber KEINE Code-Blöcke.
        """
        
        // Prompt finished in previous chunk

        
        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userPrompt)
        ]
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o", // Or gpt-3.5-turbo if preferred for cost
            messages: messages,
            temperature: 0.7
        )
        
        guard let url = URL(string: endpoint) else {
            throw AIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Log error body if possible
            if let errorText = String(data: data, encoding: .utf8) {
                print("OpenAI Error: \(errorText)")
            }
            throw AIError.invalidResponse
        }
        
        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        var content = decodedResponse.choices.first?.message.content ?? "Keine Antwort erhalten."
        
        // Post-processing: remove code blocks if AI ignores instruction
        if content.hasPrefix("```markdown") {
            content = content.replacingOccurrences(of: "```markdown", with: "")
        }
        if content.hasPrefix("```") {
            content = content.replacingOccurrences(of: "```", with: "")
        }
        if content.hasSuffix("```") {
            content = String(content.dropLast(3))
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
