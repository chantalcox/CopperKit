//
//  CopperPhoneRecord.swift
//  CopperRecordObject Representation of a phone number
//
//  Created by Doug Williams on 6/2/14.
//  Copyright (c) 2014 Doug Williams. All rights reserved.
//

import UIKit

public class CopperPhoneRecord: CopperRecordObject, CopperPhone {

    override public var isBlank:Bool {
        return phoneNumber == nil || self.number == nil
    }
    
    
    public var phoneNumber: String? {
        get {
            if let num = self.data[ScopeDataKeys.PhoneNumber.rawValue] as? String {
                return num
            }
            return String?()
        }
        set {
            if let new = newValue?.clean() where !new.isEmpty {
                self.data[ScopeDataKeys.PhoneNumber.rawValue] = new
            } else {
                self.data.removeValueForKey(ScopeDataKeys.PhoneNumber.rawValue)
            }
            self.uploaded = false
        }
    }
    
    // countryCode for this phone number
    // ISO-3166-2 expected (e.g. "US", or "UK")
    public var countryCode: String? {
        guard let nbPhoneNumber = nbPhoneNumber else {
            return nil
        }
        return CopperPhoneRecord.getCountryCodeForPrefix(nbPhoneNumber.countryCode)
    }
    
    // get this phone number (e.g. (4156130691 of +1 41561305691)
    public var number: String? {
        guard let nbPhoneNumber = nbPhoneNumber else {
            return nil
        }
        return String(nbPhoneNumber.nationalNumber)
    }
    
    // get the image for the country code of this number
    public var countryImage: UIImage? {
        guard let countryCode = self.countryCode else {
            return nil
        }
        return CopperPhoneRecord.flagForCountryCode(countryCode)
    }
    
    public class var DefaultCountryCode: String {
        if let phoneCountryCode = C29Utils.getPhoneCountryCode() {
            return phoneCountryCode
        }
        return "US"
    }
    
    // match on 5+ consecutive numbers
    let pattern = "[0-9]{5,}"
    
    public convenience init(isoNumber: String! = nil, id: String = "current", verified: Bool = false) {
        self.init(scope: C29Scope.Phone, data: nil, id: id, verified: verified)
        self.phoneNumber = isoNumber
    }
    
    // returns true if the cobject conforms to all requirements of its Type
    override public var valid: Bool {
        if super.valid {
            return true
        }
        
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: self.pattern, options: .CaseInsensitive)
        } catch _ {
            regex = nil
        }
        
        if let text = number {
            let range = NSMakeRange(0, text.characters.count)
            if let matchRange = regex?.rangeOfFirstMatchInString(text, options: .ReportProgress, range: range) {
                return matchRange.location != NSNotFound
            }
            
        }
        return false
    }
    
    
    // utility class used by to parse the phoneNumber
    private var nbPhoneNumber: NBPhoneNumber? {
        let phoneUtil = NBPhoneNumberUtil()
        let number: NBPhoneNumber!
        do {
            number = try phoneUtil.parseWithPhoneCarrierRegion(phoneNumber)
            return number
        } catch _ as NSError {
            return nil
        }
    }

    // MARK: - Country Code utilities
    
    public class func getPrefixForCountryCode(countryCode: String) -> NSNumber? {
        for (code, prefix) in PrefixCodes {
            if countryCode == code {
                let formatter = NSNumberFormatter()
                formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle;
                if let number = formatter.numberFromString(prefix) {
                    return number
                }
            }
        }
        return nil // default, TODO probably not the best solution but easy and good enough for now
    }

    class func getCountryCodeForPrefix(countryCodePrefix: NSNumber) -> String? {
        for (countryCode, prefix) in PrefixCodes {
            if prefix == countryCodePrefix.stringValue {
                return countryCode
            }
        }
        return nil // default, TODO probably not the best solution but easy and good enough for now
    }
    
    // Per: http://stackoverflow.com/questions/13022601/list-of-countries-and-country-dialing-codes-for-ios/13534627#13534627
    class var PrefixCodes: [String:String] {
        return ["US": "1", "AF": "93", "AE": "971", "AL": "355", "AN": "599", "AS":"1", "AD": "376", "AO": "244", "AI": "1", "AG":"1", "AR": "54","AM": "374", "AW": "297", "AU":"61", "AT": "43","AZ": "994", "BS": "1", "BH":"973", "BF": "226","BI": "257", "BD": "880", "BB": "1", "BY": "375", "BE":"32","BZ": "501", "BJ": "229", "BM": "1", "BT":"975", "BA": "387", "BW": "267", "BR": "55", "BG": "359", "BO": "591", "BL": "590", "BN": "673", "CC": "61", "CD":"243","CI": "225", "KH":"855", "CM": "237", "CA": "1", "CV": "238", "KY":"345", "CF":"236", "CH": "41", "CL": "56", "CN":"86","CX": "61", "CO": "57", "KM": "269", "CG":"242", "CK": "682", "CR": "506", "CU":"53", "CY":"537","CZ": "420", "DE": "49", "DK": "45", "DJ":"253", "DM": "1", "DO": "1", "DZ": "213", "EC": "593", "EG":"20", "ER": "291", "EE":"372","ES": "34", "ET": "251", "FM": "691", "FK": "500", "FO": "298", "FJ": "679", "FI":"358", "FR": "33", "GB":"44", "GF": "594", "GA":"241", "GS": "500", "GM":"220", "GE":"995","GH":"233", "GI": "350", "GQ": "240", "GR": "30", "GG": "44", "GL": "299", "GD":"1", "GP": "590", "GU": "1", "GT": "502", "GN":"224","GW": "245", "GY": "595", "HT": "509", "HR": "385", "HN":"504", "HU": "36", "HK": "852", "IR": "98", "IM": "44", "IL": "972", "IO":"246", "IS": "354", "IN": "91", "ID":"62", "IQ":"964", "IE": "353","IT":"39", "JM":"1", "JP": "81", "JO": "962", "JE":"44", "KP": "850", "KR": "82","KZ":"77", "KE": "254", "KI": "686", "KW": "965", "KG":"996","KN":"1", "LC": "1", "LV": "371", "LB": "961", "LK":"94", "LS": "266", "LR":"231", "LI": "423", "LT": "370", "LU": "352", "LA": "856", "LY":"218", "MO": "853", "MK": "389", "MG":"261", "MW": "265", "MY": "60","MV": "960", "ML":"223", "MT": "356", "MH": "692", "MQ": "596", "MR":"222", "MU": "230", "MX": "52","MC": "377", "MN": "976", "ME": "382", "MP": "1", "MS": "1", "MA":"212", "MM": "95", "MF": "590", "MD":"373", "MZ": "258", "NA":"264", "NR":"674", "NP":"977", "NL": "31","NC": "687", "NZ":"64", "NI": "505", "NE": "227", "NG": "234", "NU":"683", "NF": "672", "NO": "47","OM": "968", "PK": "92", "PM": "508", "PW": "680", "PF": "689", "PA": "507", "PG":"675", "PY": "595", "PE": "51", "PH": "63", "PL":"48", "PN": "872","PT": "351", "PR": "1","PS": "970", "QA": "974", "RO":"40", "RE":"262", "RS": "381", "RU": "7", "RW": "250", "SM": "378", "SA":"966", "SN": "221", "SC": "248", "SL":"232","SG": "65", "SK": "421", "SI": "386", "SB":"677", "SH": "290", "SD": "249", "SR": "597","SZ": "268", "SE":"46", "SV": "503", "ST": "239","SO": "252", "SJ": "47", "SY":"963", "TW": "886", "TZ": "255", "TL": "670", "TD": "235", "TJ": "992", "TH": "66", "TG":"228", "TK": "690", "TO": "676", "TT": "1", "TN":"216","TR": "90", "TM": "993", "TC": "1", "TV":"688", "UG": "256", "UA": "380", "UY": "598","UZ": "998", "VA":"379", "VE":"58", "VN": "84", "VG": "1", "VI": "1","VC":"1", "VU":"678", "WS": "685", "WF": "681", "YE": "967", "YT": "262","ZA": "27" , "ZM": "260", "ZW":"263"]
    }
    
    class func flagForCountryCode(countryCode: String) -> UIImage? {
        let bundle = NSBundle.mainBundle()
        let imagePath = bundle.resourcePath!+"/CountryPicker.bundle/"+countryCode+".png"
        return UIImage(contentsOfFile: imagePath)
    }
    

    public class func typeAheadPhoneNumber(phoneNumber: String) -> String {
        if phoneNumber.characters.count > 10 {
            return phoneNumber
        }
        
        // build the (###) ###-#### with numbers of 10 chars in length
        let num: NSMutableString = NSMutableString(string: phoneNumber)
        if phoneNumber.characters.count > 0 {
            num.insertString("(", atIndex: 0)
        }
        if phoneNumber.characters.count >= 3 {
            num.insertString(") ", atIndex: 4)
        }
        if phoneNumber.characters.count >= 6 {
            num.insertString("-", atIndex: 9)
        }
        return num as String
    }
}

extension CopperPhoneRecord : CopperStringDisplayRecord {
    
    public var displayString: String {
        var s = ""
        
        if let countryCode = self.countryCode,
            let prefix = CopperPhoneRecord.getPrefixForCountryCode(countryCode) {
            s += "+\(prefix) "
        }
        
        if let number = number {
            // build the (###) ###-#### with numbers of 10 chars in length
            if number.characters.count == 10 {
                let num: NSMutableString = NSMutableString(string: number)
                num.insertString("(", atIndex: 0)
                num.insertString(")", atIndex: 4)
                num.insertString(" ", atIndex: 5)
                num.insertString("-", atIndex: 9)
                s += "\(num)"
            } else {
                // simply display the numbers as a string, like iOS contacts app
                s += "\(number)"
            }
        }
        return s
    }
    
}

func ==(lhs: CopperPhoneRecord, rhs: CopperPhoneRecord) -> Bool {
    if lhs.id == rhs.id {
        return true
    }
    return lhs.phoneNumber == rhs.phoneNumber
}