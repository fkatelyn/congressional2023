//
//  ObjectAnalyzer.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/17/23.
//

class Analysis {
    let observations: [Observation]
    var objectCounts: [ObjectLabel:Int] = [:]
    var treeCountsText: String = ""
    
    init(_ observations: [Observation]) {
        self.observations = observations
        self.objectCounts = self.countLabel(observations)
        self.treeCountsText = String(treeCount())
    }

    /// Count labels
    ///
    /// - Returns: The count of labels as a dictionary [Label:Int]
    func countLabel(_ observations: [Observation]) -> [ObjectLabel:Int] {
        var countLabel: [ObjectLabel:Int] = [:]
        for observation in observations {
            let label = ObjectLabel.from(observation: observation)
            countLabel[label] = (countLabel[label] ?? 0) + 1
        }
        return countLabel
    }
    
    func treeCount() -> Int {
        (self.objectCounts[.ganoderna] ?? 0) +
        (self.objectCounts[.healthy] ?? 0) +
        (self.objectCounts[.nitrogen] ?? 0)
    }

    /// Check if the observation has more healthy trees
    public func isHealthy() -> Bool {
        let healthy: Int = objectCounts[.healthy] ?? 0
        let total: Int = treeCount()
        let fraction: Float = Float(healthy) / Float(total == 0 ? 1 : total)
        return fraction >= 0.5
    }
}
