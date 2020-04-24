//
//  ViewController.swift
//  TaxonomyParser
//
//  Created by arnaud on 11/03/16.
//  Copyright © 2016 Hovering Above. All rights reserved.
//

/*
    Understanding the OFF taxonomy mark up.
- Definition section are delimited by empty lines (\n). Each definition section defines a Vertex().
- A definition section can start with a "<" (smaller then sign), then this section defines a child.
- The ordering of the definition section is random. This implies that processing them in order might produce children Vertexes without a father Vertex.
- There are sections that do not define a Vertex. Lines in these blocks start with words like "synonyms", "stopwords"

*/
import Foundation

struct Language {
    var code = ""
    var name = ""
}

class OFFplists {

    // This class is implemented as a singleton
    // It is only needed by OpenFoodFactRequests.
    // An instance could be loaded for each request
    // A singleton limits however the number of file loads
    static let manager = OFFplists()
    
    fileprivate struct Constants {
        static let OpenFoodFactsExtension = "off"
        static let PlistExtension = "plist"
        static let AllergensFileName = "Allergens"
        static let AdditivesFileName = "Additives"
        static let AminoAcidsFileName = "Amino_acids"
        static let BrandsFileName = "Brands"
        static let CategoriesFileName = "Categories"
        static let CountriesFileName = "Countries"
        static let GlobalLabelsFileName = "GlobalLabels"
        static let IngredientsFileName = "Ingredients"
        // The OFF taxonomy is not good for the app.
        // The plist needs several edits:
        // - add the language iso with the two letter code
        // - remove language synonyms (not needed)
        // - capitalize languages
        static let LanguagesFileName = "Languages"
        static let MineralsFileName = "Minerals"
        static let NucleotidesFileName = "Nucleotides"
        // The OFF Nutriments taxonomy is not good for the app.
        // Remove synonyms
        // Capitalize
        // chech en:fiber, en:carbohydrates, en:cocoa (minimum)
        // add units
        static let NutrientsFileName = "Nutrients"
        static let OtherNutritionalSubstancesFileName = "Other_nutritional_substances"
        static let StatesFileName = "States"
        static let VitaminsFileName = "Vitamins"
        static let TaxonomyKey = "Taxonomy"
        static let Language = "en"
        static let LanguageDivider = ":"
    }
    
    fileprivate struct TextConstants {
        static let FileNotAvailable = "Error: file %@ not available"
    }
    
    private var OFFlanguages: Set <VertexNew>? = nil
    
    
    init() {
    }

//
// MARK: - Language functions
//
    
    func language(atIndex index: Int, languageCode key: String) -> String? {
        if OFFlanguages == nil {
            OFFlanguages = readPlist(Constants.LanguagesFileName)
        }
        if index >= 0 && OFFlanguages != nil && index <= OFFlanguages!.count {
            let currentVertex = OFFlanguages![OFFlanguages!.index(OFFlanguages!.startIndex, offsetBy: index)].leaves
            let values = currentVertex[key]
            return  values != nil ? values![0] : nil
        } else {
            return nil
        }
    }

    public var allLanguages: [Language] {
        return setupAllLanguages(Locale.preferredLanguages[0])
    }
    
    private func setupAllLanguages(_ localeLanguage: String) -> [Language] {
        var languages: [Language] = []
        if OFFlanguages == nil {
            OFFlanguages = readPlist(Constants.LanguagesFileName)
        }
        guard OFFlanguages != nil else { return languages }
        let firstSplit = localeLanguage.split(separator:"-").map(String.init)

        // loop over all verteces and fill the languages array
        for vertex in OFFlanguages! {
            var language = Language()
            if let validValues = vertex.leaves["iso"] {
                language.code = validValues[0]
            }

            let values = vertex.leaves[firstSplit[0]]
            
            language.name = values != nil ? values![0] : localeLanguage
            languages.append(language)
        }
        if languages.count > 1 {
            languages.sort(by: { (s1: Language, s2: Language) -> Bool in return s1.name < s2.name } )
        }
        return languages
    }
    
    func languageName(for languageCode:String?) -> String {
        var language: Language? = nil
        guard languageCode != nil else { return TranslatableStrings.NoLanguageDefined }
        let allLanguages: [Language] = self.allLanguages
        if let validIndex = allLanguages.firstIndex(where: { (s: Language) -> Bool in
            s.code == languageCode!
        }){
            language = allLanguages[validIndex]
        }
        
        return language != nil ? language!.name : TranslatableStrings.NoLanguageDefined
    }
    
    func languageCode(for languageString:String?) -> String {
        var language: Language? = nil
        guard languageString != nil else { return TranslatableStrings.NoLanguageDefined }
        if let validIndex = allLanguages.firstIndex(where: { (s: Language) -> Bool in
            s.name == languageString!
        }){
            language = allLanguages[validIndex]
        }
        
        return language != nil ? language!.code : TranslatableStrings.NoLanguageDefined
    }
    
           
//
// MARK: - Translate functions
//
    
    func translateLanguage(_ key: String, language:String) -> String? {
        if let taxonomy = OFFlanguages {
            return translate(key, into: language, for: taxonomy)
        }
        return String(format:TextConstants.FileNotAvailable, Constants.LanguagesFileName)
    }

    private func translate(_ key: String, into language:String, for taxonomy:Set<VertexNew>) -> String? {
        let firstSplit = language.split(separator:"-").map(String.init)[0]
        // find the Vertex.Node with the key
        if let index = taxonomy.firstIndex(of: VertexNew(key:key)) {
            let currentVertex = taxonomy[index].leaves
            if let values = currentVertex[firstSplit] {
                return  values[0] //.capitalized
            }
        }
        return nil
    }
    
//
// MARK: - Read functions
//
    fileprivate func readPlist(_ fileName: String) -> Set <VertexNew>? {
        // Copy the file from the Bundle and write it to the Device:
        if let path = Bundle.main.path(forResource: fileName, ofType: Constants.PlistExtension) {

            //let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
            //let documentsDirectory = paths.objectAtIndex(0) as! NSString
            //let path = documentsDirectory.stringByAppendingPathComponent(fileName + "." + Constants.PlistExtension)
            let resultDictionary = NSDictionary(contentsOfFile: path)
            // print("Saved plist file is --> \(resultDictionary?.description)")
            var verteces = Set <VertexNew>()
        
            if let result = resultDictionary {
                var vertex = VertexNew()
                for (key, value) in result {
                    let newKey = key as! String
                    let dict = Dictionary(dictionaryLiteral: (newKey, value))
                    vertex = vertex.decodeDict(dict)
                    verteces.insert(vertex)
                }
                return verteces
            }
        }
        return nil
    }
    
}

