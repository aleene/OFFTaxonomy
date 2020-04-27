//
//  Taxonomy.swift
//  OFFTaxonomy
//
//  Created by arnaud on 25/04/2020.
//  Copyright © 2020 Hovering Above. All rights reserved.
//

import Foundation

struct Parser {
    // Take a taxonomy file from OFF
    // Edit it in textmate
    // Save with LF as line endings and start met een hoodletter
    // drag the taxonomies into xcode
    // set the Line Endings in the Text Settings to MacOS/Unix
    // Result files can be found as: file:///Users/arnaud/Library/Developer/CoreSimulator/Devices/<device>/data/Containers/Data/Application/<app>/Documents/Additives.plist
    // These can then be c
    private struct Constants {
        static let OpenFoodFactsExtension = "txt"
        static let PlistExtension = "plist"
        static let AllergensFileName = "Allergens"
        static let AdditivesFileName = "Additives"
        static let AminoAcidsFileName = "Amino_acids"
        static let BrandsFileName = "Brands"
        static let CountriesFileName = "Countries"
        static let CategoriesFileName = "Categories"
        static let GlobalLabelsFileName = "GlobalLabels"
        static let LanguagesFileName = "Languages"
        static let IngredientsFileName = "Ingredients"
        static let MineralsFileName = "Minerals"
        static let NucleotidesFileName = "Nucleotides"
        static let NutrientsFileName = "Nutriments"
        static let OtherNutritionalSubstancesFilename = "Other_nutritional_substances"
        static let VitaminsFilename = "Vitamins"
        static let TaxonomyKey = "Taxonomy"
        static let Language = "en"
        static let LanguageDivider = ":"
        static let StatesFileName = "States"
    }
    

}
