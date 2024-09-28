//
//  Preferences.swift
//  feather
//
//  Created by samara on 5/17/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import Foundation
import UIKit

enum Preferences {
	static var installPathChangedCallback: ((String?) -> Void)?
	static let defaultInstallPath: String = "https://api.palera.in"
	
	@Storage(key: "Feather.UserSpecifiedOnlinePath", defaultValue: defaultInstallPath)
	static var onlinePath: String? { didSet { installPathChangedCallback?(onlinePath) } }
	
	@Storage(key: "Feather.UserSelectedServer", defaultValue: false)
	static var userSelectedServer: Bool
	
	@Storage(key: "Feather.DefaultRepos", defaultValue: false)
	// Default repo is from the repository
	static var defaultRepos: Bool
	
	@Storage(key: "Feather.automaticInstall", defaultValue: true)
	static var automaticInstall: Bool
	
	@Storage(key: "Feather.userIntefacerStyle", defaultValue: UIUserInterfaceStyle.unspecified.rawValue)
	static var preferredInterfaceStyle: Int
	
	@CodableStorage(key: "Feather.AppTintColor", defaultValue: CodableColor(UIColor(hex: "848ef9")))
	static var appTintColor: CodableColor
	
	@Storage(key: "Feather.OnboardingActive", defaultValue: true)
	static var isOnboardingActive: Bool
	
	@Storage(key: "Feather.selectedCert", defaultValue: 0)
	static var selectedCert: Int
	
	@Storage(key: "Feather.ppqcheckBypass", defaultValue: "")
	// random string
	static var pPQCheckString: String
	
	@Storage(key: "Feather.fuckOffPpqcheckDetection", defaultValue: true)
	static var isFuckingPPqcheckDetectionOff: Bool
	
	@Storage(key: "Feather.CertificateTitleAppIDtoTeamID", defaultValue: false)
	static var certificateTitleAppIDtoTeamID: Bool
	
	@Storage(key: "Feather.idWhitelist", defaultValue: ["kh.crysalis.feather", "kh.crysalis.feather2"])
	// Unused
	static var idWhitelist: [String]
	
	@Storage(key: "Feather.AppDescriptionAppearance", defaultValue: 0)
	// 0 == Default appearance
	// 1 == Replace subtitle with localizedDescription
	// 2 == Move localizedDescription below app icon, and above screenshots
	static var appDescriptionAppearance: Int
	
	@Storage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
	/// Preferred language
	static var preferredLanguageCode: String?
	
	
	@Storage(key: "Feather.Beta", defaultValue: false)
	//
	static var beta: Bool
	
}
// MARK: - Callbacks
fileprivate extension Preferences {
	static func preferredLangChangedCallback(newValue: String?) {
		Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
	}
}
// MARK: - Color

struct CodableColor: Codable {
	let red: CGFloat
	let green: CGFloat
	let blue: CGFloat
	let alpha: CGFloat
	
	var uiColor: UIColor {
		return UIColor(red: self.red, green: self.green, blue: self.blue, alpha: self.alpha)
	}
	
	init(_ color: UIColor) {
		var _red: CGFloat = 0, _green: CGFloat = 0, _blue: CGFloat = 0, _alpha: CGFloat = 0
		
		color.getRed(&_red, green: &_green, blue: &_blue, alpha: &_alpha)
		
		self.red = _red
		self.blue = _blue
		self.green = _green
		self.alpha = _alpha
	}
}

