//
//  main.swift
//  XMLParser
//
//  Created by Mac Mini 2021_1 on 29/09/2022.
//

import Foundation

protocol XMLParseDelegate : NSObjectProtocol {
    func xmlParseDelegateDidStartParsing(_ parser: XMLParser)
    func xmlParseDelegateDidFinishParsing(_ parser: XMLParser, results : [String : Any], time: TimeInterval)
}

class XMLParse : NSObject {
    
    static let shared = XMLParse()
    
    private var parser:XMLParser!
    private var elementParse:XLMParserElementWrap?
    
    // protocol callback
    weak var delegate : XMLParseDelegate?
    
    // output parsing
    var parsingResult = [String:Any]()
    
    private var keyFlagOpen = [String]()
    private var headerPrevious = ""
    
    // time start parsing
    private var timer = TimeInterval()
    
    //is running parse
    var isRunning = false
    
    var isOpen = false
    
    override init() {}
    
    init(element : [String]) {
        self.elementParse = XLMParserElementWrap.init(element: element)
        
    }
    
    func parsingXML(with data: Data?) -> Bool {
        if let data = data {
            self.parser = XMLParser(data: data)
            let success = start()
            return success
        }
        return false
    }
    
    func parsingXMLFile(with path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        if let parser = XMLParser(contentsOf: url) {
            self.parser = parser
            let success = start()
            return success
        }
        return false
    }
    
    func start() -> Bool {
        self.parser.delegate = self
        let successed = self.parser.parse()
        return successed
    }
    
    // not using delegate
    func resultsParsing() -> [String : Any]? {
        if !isRunning {
            return self.parsingResult
        }
        return nil
    }
    
    //get timer parsing
    func getTimerParsing() -> TimeInterval {
        if !isRunning {
            return self.timer
        }
        return 0
    }
    
    func getPropertiesXMLElement() -> [String : Any]? {
        if !isRunning {
            return self.elementParse?.property
        }
        return nil
    }
    
}

extension XMLParse : XMLParserDelegate {
    
    func parserDidStartDocument(_ parser: XMLParser) {
        print("Did start parsing xml")
        self.isRunning = true
        self.timer = Date.timeIntervalSinceReferenceDate
        self.delegate?.xmlParseDelegateDidStartParsing(parser)
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        print("Did end parsing xml")
        self.isRunning = false
        self.timer = Date.timeIntervalSinceReferenceDate - self.timer
        self.parser.abortParsing()
        self.parser = nil
        self.delegate?.xmlParseDelegateDidFinishParsing(parser , results: parsingResult, time: self.timer)
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if isRunning {
            guard let elementParse = self.elementParse else {
                print("No have base element can not parse XML")
                return
            }
            
            guard elementParse.element != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            guard elementParse.flagElement != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            if attributeDict.count > 0 {
                self.elementParse?.property[elementName] = attributeDict
            }
            
            print("headerNow: \(elementName)")
            self.elementParse?.flagElement![elementName] = true
            keyFlagOpen.append(elementName)
            
            if self.headerPrevious != "" && self.elementParse?.flagElement![self.headerPrevious] == true {
                self.parsingResult = self.setKeyForDict(key: self.parsingResult, keyOpen: keyFlagOpen)
                print("parsingResult: \(parsingResult)")
            }
            
            self.headerPrevious = elementName
        }
    }

    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        isOpen = false
        
        if isRunning {
            guard let elementParse = self.elementParse else {
                print("No have base element can not parse XML")
                return
            }
            
            guard elementParse.element != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            self.elementParse?.flagElement![elementName] = false
            
            guard elementParse.flagElement != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            let index = keyFlagOpen.firstIndex(of: elementName)
            keyFlagOpen.remove(at: index!)
            self.elementParse?.flagElement![elementName] = false
            if keyFlagOpen.count > 0 {
                self.headerPrevious = keyFlagOpen.last!
            }
        }
    }

    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if isRunning {
            guard let elementParse = self.elementParse else {
                print("No have base element can not parse XML")
                return
            }
            
            guard elementParse.element != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            guard elementParse.flagElement != nil else {
                print("No have base element can not parse XML")
                return
            }
            
            self.parsingResult = self.setValueForDict(key : self.parsingResult ,keyOpen: self.headerPrevious, values: string)
            print("parsingResult: \(parsingResult)")
        }
    }
    
}

extension XMLParse {
    
    private class XLMParserElementWrap {
        
        let countElement:Int
        
        let element:[String]?
        
        var property:[String:[String:String]]!
        
        var flagElement:[String:Bool]?
        
        init() {
            self.element = [String]()
            self.flagElement = [String:Bool]()
            self.property = [String:[String:String]]()
            self.countElement = 0
        }
        
        init(element : [String] ) {
            self.element = element
            self.countElement = element.count
            self.flagElement = [String:Bool]()
            self.property = [String:[String:String]]()
        }
    }
    
    func setKeyForDict(key: [String:Any], keyOpen : [String]?, value : String? = nil) -> [String:Any]{
        var dict = key
        if var keys = keyOpen, keys.count > 0 {
            if keys.count == 1 {
                if value == nil {
                    dict[keys[0]] = [String:Any]()
                } else {
                    dict[keys[0]] = value
                }
                return dict
            }
            
            keys.removeFirst()
            
            if dict.count > 0 {
                dict[keyOpen![0]] = setKeyForDict(key: dict[keyOpen![0]] as! [String : Any], keyOpen: keys, value: value)
            } else {
                dict[keyOpen![0]] = setKeyForDict(key: dict, keyOpen: keys, value: value)
            }
            
        }
        return dict
    }
    
    func setValueForDict(key: [String:Any], keyOpen : String, values : String) -> [String:Any] {
        var dict = key
        
        for (key,value) in dict {
            if key == keyOpen {
                dict[key] = values
                return dict
            }
            if let val = value as? [String : Any] {
                dict[key] = setValueForDict(key : val, keyOpen: keyOpen, values: values)
            }
        }
        
        return dict
    }
    
}


// MARK: - Run

func parserXML() {
    /*
     xml example
     <?xml version="1.0" encoding="UTF-8"?>
         <Envelop>
             <Header type="open">
                 <name>Ho Chi Minh</name>
                 <id>10</id>
             </Header>
             <Body lat="22.54297276" lon="102.854709076">
                 <ele>1318.59</ele>
                 <time>2022-09-28T02:01:15Z</time>
             </Body>
         </Envelop>
     */
    
    /*
     <?xml version="1.0" encoding="UTF-8"?>
         <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
             <SOAP-ENV:Header>
                 <wsa:MessageID>urn:uuid:xxxx-xxxx-xxxx-xxxx</wsa:MessageID>
                 <wsa:To SOAP-ENV:mustUnderstand="true">urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>
             </SOAP-ENV:Header>
             <SOAP-ENV:Body>
                 <tns:Probe>
                     <tns:Types>dn:NetworkVideoTransmitter</tns:Types>
                 </tns:Probe>
             </SOAP-ENV:Body>
         </SOAP-ENV:Envelope>
     */
    
    let stringXML = """
    <?xml version="1.0" encoding="UTF-8"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ><SOAP-ENV:Header><wsa:MessageID>urn:uuid:xxxx-xxxx-xxxx-xxxx</wsa:MessageID><wsa:To SOAP-ENV:mustUnderstand="true">urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To></SOAP-ENV:Header><SOAP-ENV:Body><tns:Probe><tns:Types>dn:NetworkVideoTransmitter</tns:Types></tns:Probe></SOAP-ENV:Body></SOAP-ENV:Envelope>
    """
    
    let stringXML_2 = """
    <?xml version="1.0" encoding="UTF-8"?><Commands><command type="open"><name>Ho Chi Minh</name><id>10</id></command><trkpt lat="22.54297276" lon="102.854709076"><ele>1318.59</ele><time>2022-09-28T02:01:15Z</time></trkpt></Commands>
    """

    let parser = XMLParse.init(element: [
        "SOAP-ENV:Envelope",
        "SOAP-ENV:Header",
        "wsa:MessageID",
        "wsa:To",
        "SOAP-ENV:Body",
        "tns:Types"
    ])

    let success = parser.parsingXML(with: stringXML.data(using: .utf8))

    if success {
        let results = parser.resultsParsing()
        let property = parser.getPropertiesXMLElement()
        print("Properties : \(String(describing: property))")
        print("Value : \(String(describing: results))")
        print("Times : \(parser.getTimerParsing())")
    }
}

// MARK: - Main

parserXML()


