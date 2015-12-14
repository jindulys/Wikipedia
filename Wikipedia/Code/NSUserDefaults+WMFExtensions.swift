
import Foundation

let WMFAppLaunchDateKey = "WMFAppLaunchDateKey"
let WMFAppBecomeActiveDateKey = "WMFAppBecomeActiveDateKey"
let WMFAppResignActiveDateKey = "WMFAppResignActiveDateKey"
let WMFOpenArticleTitleKey = "WMFOpenArticleTitleKey"


extension NSUserDefaults {
    
    public func wmf_dateForKey(key: String) -> NSDate? {
        return self.objectForKey(key) as? NSDate
    }

    public func wmf_appLaunchDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppLaunchDateKey)
    }
    
    public func wmf_setAppLaunchDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppLaunchDateKey)
        self.synchronize()
    }
    
    public func wmf_appBecomeActiveDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppBecomeActiveDateKey)
    }
    
    public func wmf_setAppBecomeActiveDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppBecomeActiveDateKey)
        self.synchronize()
    }
    
    public func wmf_appResignActiveDate() -> NSDate? {
        return self.wmf_dateForKey(WMFAppResignActiveDateKey)
    }
    
    public func wmf_setAppResignActiveDate(date: NSDate) {
        self.setObject(date, forKey: WMFAppResignActiveDateKey)
        self.synchronize()
    }
    
    public func wmf_openArticleTitle() -> MWKTitle? {
        if let data = self.dataForKey(WMFOpenArticleTitleKey){
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MWKTitle
        }else{
            return nil
        }
    }
    
    public func wmf_setOpenArticleTitle(title: MWKTitle?) {
        if let title = title {
            let data = NSKeyedArchiver.archivedDataWithRootObject(title)
            self.setObject(data, forKey: WMFOpenArticleTitleKey)
        }else{
            self.removeObjectForKey(WMFOpenArticleTitleKey)
        }
        self.synchronize()
    }

    public func wmf_setSendUsageReports(enabled: Bool) {
        self.setObject(NSNumber(bool: enabled), forKey: "SendUsageReports")
        self.synchronize()

    }

    public func wmf_sendUsageReports() -> Bool {
        if let enabled = self.objectForKey("SendUsageReports") as? NSNumber {
            return enabled.boolValue
        }else{
            return false
        }
    }

}