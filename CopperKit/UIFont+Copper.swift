//
//  UIFont+Copper.swift
//  Copper
//
//  Created by Benjamin Sandofsky on 8/21/15.
//  Copyright © 2015 Copper Technologies, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    
    // MARK: Programmatic styling
    
    public class var C29_Body: UIFont {
        return UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
    }
    
    public class var C29_H2: UIFont {
        return UIFont.systemFontOfSize(30.0, weight: UIFontWeightRegular)
    }

    public class var C29_H3: UIFont {
        return UIFont.systemFontOfSize(23.0, weight: UIFontWeightRegular)
    }
    
    public class var C29_H4: UIFont {
        return UIFont.systemFontOfSize(20.0, weight: UIFontWeightRegular)
    }
    
    // MARK: View Specific fonts

    public class func copper_SectionHeaderFont() -> UIFont {
        let font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightBold)
        return font
    }

    public class func copper_PrimaryFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        return font
    }
    
    public class func copper_PrimaryItalicsFont() -> UIFont {
        let font = UIFont.italicSystemFontOfSize(17.0)
        return font
    }
    
    public class func copper_SecondaryFont() -> UIFont {
        let font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightRegular)
        return font
    }
    
    public class func copper_IdentitySheetNameFont() -> UIFont {
        let font = UIFont.systemFontOfSize(20.0, weight: UIFontWeightRegular)
        return font
    }

    public class func copper_IdentitySheetToggleValueLabelFont() -> UIFont {
        let font = UIFont.systemFontOfSize(15.0, weight: UIFontWeightMedium)
        return font
    }
    
    public class func copper_ClientIconFont() -> UIFont {
        let font = UIFont.systemFontOfSize(45.0, weight: UIFontWeightLight)
        return font
    }
    
    public class func copper_RequestSheetHeaderNameFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightLight)
        return font
    }
    
    public class func copper_RequestSheetOpenWithCopperFont() -> UIFont {
        let font = UIFont.systemFontOfSize(19.0, weight: UIFontWeightBold)
        return font
    }
    
    // MARK: Cards
    
    public class func copper_CardHeaderTitleFont() -> UIFont {
        let font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightBold)
        return font
    }
    
    public class func copper_CardHeaderSubtitleFont() -> UIFont {
        let font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightRegular)
        return font
    }
    
    // MARK: Settings
    
    public class func copper_SettingsTableSectionHeaderFont() -> UIFont {
        let font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightMedium)
        return font
    }
    
    public class func copper_SettingsTableViewFooterVersionFont() -> UIFont {
        let font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightMedium)
        return font
    }
    
    public class func copper_SettingsTableViewNavigationControllerFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        return font
    }
    
    public class func copper_SettingsTableViewCellSecondaryTextFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        return font
    }
    
    public class func copper_SettingsTableViewNavigationControllerBackFont() -> UIFont {
        let font = UIFont.systemFontOfSize(10.0, weight: UIFontWeightMedium)
        return font
    }

    // MARK: Contacts Picker
    
    public class func copper_CopperContactsPickerCellFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        return font
    }
    
    public class func copper_ContactsPickerNavigationBarFont() -> UIFont {
        let font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
        return font
    }
    
    public class func copper_ContactsPickerNavigationButtonFont() -> UIFont {
        return UIFont.systemFontOfSize(20.0, weight: UIFontWeightRegular)
    }
    
    // MARK: Onboarding View
    
    public class func copper_OnboardingViewTextFont() -> UIFont {
        return UIFont.systemFontOfSize(40.0, weight: UIFontWeightRegular)
    }
    
    public class func copper_OnboardingViewSubTextFont() -> UIFont {
        return UIFont.systemFontOfSize(20.0, weight: UIFontWeightRegular)
    }
    
    public class func copper_OnboardingViewContinueButtonFont() -> UIFont {
        return UIFont.systemFontOfSize(22.0, weight: UIFontWeightMedium)
    }
    
    public class func copper_OnboardingViewLegalButtonFont() -> UIFont {
        return UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
    }
    
    // MARK: Registration View
    
    public class func copper_RegistrationViewSuccessMessageFont() -> UIFont {
        return UIFont.systemFontOfSize(30.0, weight: UIFontWeightRegular)
    }
    
    public class func copper_RegistrationViewControlPlaceholderFont() -> UIFont {
        return UIFont.systemFontOfSize(17.0, weight: UIFontWeightRegular)
    }
    
    public class func copper_RegistrationViewControlLabelFont() -> UIFont {
        return UIFont.systemFontOfSize(9.0, weight: UIFontWeightMedium)
    }
    
    public class func copper_RegistrationViewNumberPadFont() -> UIFont {
        return UIFont.systemFontOfSize(28.0, weight: UIFontWeightRegular)
    }
    
    public class func copper_RegistrationViewNumberPadPressedFont() -> UIFont {
        return UIFont.systemFontOfSize(34.0, weight: UIFontWeightRegular)
    }
    
    // MARK: Document Viewer
    
    public class func copper_DocumentViewerNavBarFont() -> UIFont {
        return UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
    }
}