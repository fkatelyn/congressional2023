//
//  ObjectAnalyzer.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/17/23.
//

struct Analyze {
    let observations: [Observation]
    

    /// Count labels
    ///
    /// - Returns: The count of labels as a dictionary [Label:Int]
    func countLabel(observations: [Observation]) -> [ObjectLabel:Int] {
        var countLabel: [ObjectLabel:Int] = [:]
        for observation in observations {
            let label = ObjectLabel.from(observation: observation)
            countLabel[label] = (countLabel[label] ?? 0) + 1
        }
        return countLabel
    }

    /// Check if the observation has more healthy trees
    func isHealthy() -> Bool {
        let countLabel = countLabel(observations: observations)
        let healthy: Int = countLabel[.healthy] ?? 0
        let malnutrition: Int = countLabel[.nitrogen] ?? 0
        let ganoderna: Int = countLabel[.ganoderna] ?? 0
        let total: Int = healthy + malnutrition + ganoderna
        let fraction: Float = Float(healthy) / Float(total == 0 ? 1 : total)
        return fraction >= 0.5
    }
}
