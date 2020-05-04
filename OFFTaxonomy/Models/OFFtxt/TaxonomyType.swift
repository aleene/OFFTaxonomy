//
//  TaxonomyType.swift
//  OFFTaxonomy
//
//  Created by arnaud on 27/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation

enum TaxonomyType: CaseIterable {
    private struct Constant {
        static let OpenFoodFactsExtension = "txt"
        static let PlistExtension = "plist"
        static let TaxonomyKey = "Taxonomy"
        static let Language = "en"
        static let LanguageDivider = ":"
    }
    
    case processes
    case languages

    public var filename: String {
        switch self {
        case .processes: return "Processes"
        case .languages: return "Languages"
        }
    }
    
    public func read() -> ([ATParticle], [ATSpring]) {
        
        let offTaxonomy = BHTaxonomy()
        
        // read file in /InputTaxonomies/Allergens.txt
        if let path = Bundle.main.path(forResource: self.filename, ofType: Constant.OpenFoodFactsExtension) {
            
            // if there is a file, a corresponding struct can be created
            do {
                let file = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
                var currentSection = Section()
                
                // transform file in Array with lines
                let fileLines = file.components(separatedBy: NSCharacterSet.newlines)
                
                // analyse line by line
                for line in fileLines {
                    // is it a taxonomy line?
                    guard !line.hasPrefix("== Taxonomy") else { continue }
                    guard !line.hasPrefix("2 letters") else { continue }
                    guard !line.hasPrefix("Taxonomy") else { continue }
                    guard !line.hasPrefix("</pre>") else { continue }
                    guard !line.hasPrefix("<pre>") else { continue }
                    guard !line.hasPrefix("synonyms") else { continue }
                    guard !line.hasPrefix("e_number") else { continue }
                    guard !line.hasPrefix("wikidata") else { continue }
                    guard !line.hasPrefix("colour_index") else { continue }
                    guard !line.hasPrefix("#") else { continue }
                    guard !line.hasPrefix("country") else { continue }
                    guard !line.hasPrefix("official") else { continue }
                    guard !line.hasPrefix("stopwords") else { continue }
                    guard !line.hasPrefix("pnns_group_1") else { continue }
                    guard !line.hasPrefix("pnns_group_2") else { continue }
                    guard !line.hasPrefix("grapevariety") else { continue }
                    guard !line.hasPrefix("region") else { continue }
                    guard !line.hasPrefix("instanceof") else { continue }
                    guard !line.hasPrefix("address") else { continue }
                    guard !line.hasPrefix("city") else { continue }
                    guard !line.hasPrefix("name") else { continue }
                    guard !line.hasPrefix("postalcode") else { continue }
                    guard !line.hasPrefix("website") else { continue }
                    
                    // where are we in the taxonomy?
                    // either a new Vertex OR a new leaf
                    //
                    // find first empty element or newline?
                    if (line.isEmpty) {
                        // this will be the start of a new section and Vertex
                        
                        // wrap up the previous section
                        if !currentSection.leaves.isEmpty {
                            currentSection.key = currentSection.normalizeKey()
                            offTaxonomy.sections.append(currentSection)
                        }
                        
                        // reset Vertex section
                        currentSection = Section()
                        
                    } else if (line.hasPrefix("<")) {
                        // a section preceding with a < defines a parent.
                        // a section might have multiple parents.
                        let firstSplit = line.split{ $0 == "<" }.map(String.init)
                        // what comes after the <, is the key for the parent
                        currentSection.parentKeys.append(firstSplit[0])
                        
                    } else if (line.hasPrefix("§")) {
                        // a section preceding with a < defines a parent.
                        // a section might have multiple parents.
                        let firstSplit = line.split{ $0 == "§" }.map(String.init)
                        // what comes after the §, is the key
                        currentSection.key = firstSplit[0]

                    } else {
                        // a standard line should be split in a language and values part
                        let firstSplit = line.split{ $0 == ":" }.map(String.init)
                        
                        // language part (colon) is missing
                        guard firstSplit.count > 1 else {
                            print("Wrong markup in line \"\(firstSplit[0])\" (: missing?)")
                            continue
                        }
                        
                        let language = firstSplit[0]

                        // the values part should be split in separate values
                        if firstSplit.count > 1 {
                            currentSection.leaves[language]  = firstSplit[1].split{ $0 == "," }.map(String.init)
                        }
                        // set the key for this Vertex / section as the first pass language
                        if currentSection.key.isEmpty {
                            currentSection.key = currentSection.alternativeKey()
                        }
                    }
                    
                } // end for
                
                // wrap up the last entry if needed
                // is this actually needed? If an empty line is missing?
                if !currentSection.leaves.isEmpty {
                    print("Empty line missing")
                    currentSection.key = currentSection.normalizeKey()

                    offTaxonomy.sections.append(currentSection)
                }
            } // end do
            catch {/* error handling here */
                print("Error reading file")
            }
        } // end if
        // create ATParticle's
        let nodes = Array(offTaxonomy.createNodes())
        // create edges from the off file
        let edges = Array(offTaxonomy.createEdges())
        return (nodes, edges)
    }
    
}
