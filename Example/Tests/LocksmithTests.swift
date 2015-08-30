//
//  LocksmithTests.swift
//  LocksmithTests
//
//  Created by Matthew Palmer on 27/06/2015.
//  Copyright © 2015 Matthew Palmer. All rights reserved.
//

import XCTest
import Locksmith

class LocksmithTests: XCTestCase {
    let userAccount = "myUser"
    let service = "myService"
    
    typealias TestingDictionaryType = [String: String]
    
    func clear() {
        do {
            try Locksmith.deleteDataForUserAccount(userAccount, inService: service)
            try Locksmith.deleteDataForUserAccount(userAccount)
        } catch {
            // no-op
        }
    }
    
    override func setUp() {
        clear()
    }
    
    override func tearDown() {
        clear()
    }
    
    func testStaticMethods() {
        let data = ["some": "data"]
        try! Locksmith.saveData(data, forUserAccount: userAccount, inService: service)
        
        let loaded = Locksmith.loadDataForUserAccount(userAccount, inService: service)! as! TestingDictionaryType
        XCTAssertEqual(loaded, data)
        
        try! Locksmith.deleteDataForUserAccount(userAccount, inService: service)
        
        let otherData: TestingDictionaryType = ["something": "way different"]
        try! Locksmith.saveData(otherData, forUserAccount: userAccount, inService: service)
        
        let loadedAgain = Locksmith.loadDataForUserAccount(userAccount, inService: service)! as! TestingDictionaryType
        XCTAssertEqual(loadedAgain, otherData)
        
        let updatedData = ["this update": "brings the ruckus"]
        try! Locksmith.updateData(updatedData, forUserAccount: userAccount, inService: service)
        
        let loaded3 = Locksmith.loadDataForUserAccount(userAccount, inService: service)! as! TestingDictionaryType
        
        XCTAssertEqual(loaded3, updatedData)
    }
    
    func testStaticMethodsForDefaultService() {
        let data = ["some": "data"]
        try! Locksmith.saveData(data, forUserAccount: userAccount)
        
        let loaded = Locksmith.loadDataForUserAccount(userAccount)! as! TestingDictionaryType
        XCTAssertEqual(loaded, data)
        
        try! Locksmith.deleteDataForUserAccount(userAccount)
        
        let otherData: TestingDictionaryType = ["something": "way different"]
        try! Locksmith.saveData(otherData, forUserAccount: userAccount)
        
        let loadedAgain = Locksmith.loadDataForUserAccount(userAccount)! as! TestingDictionaryType
        XCTAssertEqual(loadedAgain, otherData)
        
        let updatedData = ["this update": "brings the ruckus"]
        try! Locksmith.updateData(updatedData, forUserAccount: userAccount)
        
        let loaded3 = Locksmith.loadDataForUserAccount(userAccount)! as! TestingDictionaryType
        
        XCTAssertEqual(loaded3, updatedData)
    }
    
    func createGenericPasswordWithData(data: [String: AnyObject]) {
        struct CreateGenericPassword: CreateableSecureStorable, GenericPasswordSecureStorable {
            let data: [String: AnyObject]
            let account: String
            let service: String
        }
        
        let create = CreateGenericPassword(data: data, account: userAccount, service: service)
        try! create.createInSecureStore() // make sure it doesn't throw
    }
    
    func testCreateForGenericPassword() {
        let data = ["some": "data"]
        createGenericPasswordWithData(data)
    }
    
    func testLoadForGenericPassword() {
        let data = ["one": "two"]
        createGenericPasswordWithData(data)
        
        struct ReadGenericPassword: ReadableSecureStorable, GenericPasswordSecureStorable {
            let account: String
            let service: String
        }
        
        let read = ReadGenericPassword(account: userAccount, service: service)
        let actual = read.readFromSecureStore()!.data as! TestingDictionaryType
        XCTAssertEqual(actual, data)
    }
    
    func testDeleteForGenericPassword() {
        let initialData = ["one": "two"]
        
        createGenericPasswordWithData(initialData)
        
        struct DeleteGenericPassword: DeleteableSecureStorable, GenericPasswordSecureStorable {
            let account: String
            let service: String
        }
        
        let delete = DeleteGenericPassword(account: userAccount, service: service)
        try! delete.deleteFromSecureStore()
        
        let d = Locksmith.loadDataForUserAccount(userAccount, inService: service)
        XCTAssert(d == nil)
    }
    
    func testReturnedValuesForOptionalAttributes() {
        let initialData = ["one": "two"]
        
        struct Create: CreateableSecureStorable, GenericPasswordSecureStorable {
            let account: String
            let service: String
            let comment: String?
            let description: String?
            let creator: UInt?
            let data: [String: AnyObject]
        }
        
        let creator: UInt = 5
        let comment = "this is a comment"
        let description = "this is the description"
        let c = Create(account: userAccount, service: service, comment: comment, description: description, creator: creator, data: initialData)
        try! c.createInSecureStore()
        
        struct Read: ReadableSecureStorable, GenericPasswordSecureStorable {
            let account: String
            let service: String
        }
        
        let r = Read(account: userAccount, service: service)
        let d = r.readFromSecureStore()
        
        XCTAssertEqual(d?.account, userAccount)
        XCTAssertEqual(d?.service, service)
        XCTAssertEqual(d!.data as! [String: String], initialData)
        XCTAssertEqual(d?.creator, creator)
        XCTAssertEqual(d?.comment, comment)
        XCTAssertEqual(d?.description, description)
        
        XCTAssertNil(d?.generic)
        XCTAssertNil(d?.isInvisible)
    }
    
    func assertStringPairsMatchInDictionary(dictionary: NSDictionary, pairs: [(key: CFString, expectedOutput: String)]) {
        for pair in pairs {
            let a = dictionary[String(pair.0)] as! CFStringRef
            XCTAssertEqual(a as String, pair.1)
        }
    }
    
    func testInternetPasswordAttributesAreAppliedForConformingTypes() {
        struct CreateInternetPassword: CreateableSecureStorable, InternetPasswordSecureStorable {
            let account: String
            let service: String
            let data: [String: AnyObject]
            let server: String
            let port: String
            let internetProtocol: LocksmithInternetProtocol
            let authenticationType: LocksmithInternetAuthenticationType
            let path: String?
            let securityDomain: String?
            
            let performRequestClosure: PerformRequestClosureType
        }
        
        let account = "myUser"
        let port = "8080"
        let internetProtocol = LocksmithInternetProtocol.HTTP
        let authenticationType = LocksmithInternetAuthenticationType.HTTPBasic
        let path = "some_path"
        let securityDomain = "secdomain"
        let data = ["some": "data"]
        let server = "server"
        
        let performRequestClosure: PerformRequestClosureType = { (requestReference, result) in
            let dict = requestReference as NSDictionary
            
            self.assertStringPairsMatchInDictionary(dict, pairs: [
                (kSecAttrAccount, account),
                (kSecAttrPort, port),
                (kSecAttrProtocol, internetProtocol.rawValue),
                (kSecAttrAuthenticationType, authenticationType.rawValue),
                (kSecAttrPath, path),
                (kSecAttrSecurityDomain, securityDomain),
                (kSecAttrServer, server),
                (kSecClass, String(kSecClassInternetPassword))
                ])
            
            return errSecSuccess
        }
        
        let create = CreateInternetPassword(account: account, service: service, data: data, server: server, port: port, internetProtocol: internetProtocol, authenticationType: authenticationType, path: path, securityDomain: securityDomain, performRequestClosure: performRequestClosure)
        try! create.createInSecureStore()
    }
    
    func testGenericPasswordOptionalAttributesAreAppliedForConformingTypes() {
        struct CreateGenericPassword: CreateableSecureStorable, GenericPasswordSecureStorable {
            let data: [String: AnyObject]
            let account: String
            let service: String
            let accessGroup: String?
            let description: String?
            let creator: UInt?
            var performRequestClosure: PerformRequestClosureType
            let accessible: LocksmithAccessibleOption?
            let comment: String?
            let type: UInt?
            let isInvisible: Bool?
            let isNegative: Bool?
            let generic: NSData?
        }
        
        let data: [String: AnyObject] = ["some": "data"]
        let account: String = "myUser"
        let service: String = "myService"
        let accessGroup: String = "myAccessGroup"
        let description: String = "myDescription"
        let creator: UInt = 5
        let accessible: LocksmithAccessibleOption = LocksmithAccessibleOption.Always
        let comment: String = "myComment"
        let type: UInt = 10
        let isInvisible: Bool = false
        let isNegative: Bool = false
        let generic: NSData = NSData()
        
        let performRequestClosure: PerformRequestClosureType = { (requestReference, result) in
            let dict = requestReference as NSDictionary
            
            self.assertStringPairsMatchInDictionary(dict, pairs: [
                (kSecAttrAccount, account),
                (kSecAttrService, service),
                (kSecAttrAccessGroup, accessGroup),
                (kSecAttrDescription, description),
                (kSecAttrComment, comment),
                (kSecAttrAccessible, accessible.rawValue),
                (kSecClass, String(kSecClassGenericPassword))
                ])
            
            let cr = dict[String(kSecAttrCreator)] as! CFNumberRef
            XCTAssertEqual(cr as UInt, creator)
            
            let ty = dict[String(kSecAttrType)] as! CFNumberRef
            XCTAssertEqual(ty as UInt, type)
            
            let inv = dict[String(kSecAttrIsInvisible)] as! CFBooleanRef
            XCTAssertEqual(inv as Bool, isInvisible)
            
            let neg = dict[String(kSecAttrIsNegative)] as! CFBooleanRef
            XCTAssertEqual(neg as Bool, isNegative)
            
            let gen = dict[String(kSecAttrGeneric)] as! CFDataRef
            XCTAssertEqual(gen, generic)
            
            return errSecSuccess
        }
        
        let create: CreateGenericPassword = CreateGenericPassword(data: data, account: account, service: service, accessGroup: accessGroup, description: description, creator: creator, performRequestClosure: performRequestClosure, accessible: accessible, comment: comment, type: type, isInvisible: isInvisible, isNegative: isNegative, generic: generic)
        
        try! create.createInSecureStore()
    }
}
