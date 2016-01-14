//
//  main.swift
//  cocoa-redundant-l10n
//
//  Created by Andrew Pleshkov on 13.01.16.
//  Copyright © 2016 Andrew Pleshkov. All rights reserved.
//

import Foundation

func isUsedKey(key: String, atSearchPath searchPath: String) -> Bool {
    let task = NSTask()
    task.launchPath = "/usr/bin/grep"
    task.arguments = [
        "\"\(key)\"",
        "-r",
        "-s",
        "-q",
        "-h",
        "-c",
        "-m 1",
        "--include=*.m",
        searchPath
    ]
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

func keysFromStringsAtURL(url: NSURL) -> [String]? {
    guard let lines = try? NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding).componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) else {
        return nil
    }
    var keys = [String]()
    for entry in lines {
        let components = entry.componentsSeparatedByString("\"")
        if components.count > 1 {
            keys.append(components[1])
        }
    }
    return keys
}

if Process.argc < 2 {
    print("Usage: cocoa-redundant-l10n PROJECT_DIR")
    exit(1)
}

let projectPath = Process.arguments[1]
let projectURL = NSURL(fileURLWithPath: projectPath)

let fileManager = NSFileManager.defaultManager()

var dirs: [NSURL] = {
    
    var list = [NSURL]()
    
    func isDirectoryAtURL(url: NSURL) -> Bool {
        var ref: AnyObject?
        do {
            try url.getResourceValue(&ref, forKey: NSURLIsDirectoryKey)
        } catch {
            return false
        }
        guard let value = ref as? NSNumber else {
            return false
        }
        return value.boolValue
    }
    
    func dirsAtURL(root: NSURL) {
        if let rawList = try? fileManager.contentsOfDirectoryAtURL(root, includingPropertiesForKeys: nil, options: []) {
            for entry in rawList {
                if !isDirectoryAtURL(entry) {
                    continue
                }
                if entry.pathExtension == "lproj" {
                    list.append(entry)
                } else {
                    dirsAtURL(entry)
                }
            }
        }
    }
    
    dirsAtURL(projectURL)
    
    return list
}()

if dirs.count == 0 {
    print("No lproj-directories found")
    exit(1)
}

for lprojURL in dirs {
    guard let rawList = try? fileManager.contentsOfDirectoryAtURL(lprojURL, includingPropertiesForKeys: nil, options: []) else {
        continue
    }
    for entry in rawList {
        if entry.pathExtension != "strings" {
            continue
        }
        guard let filePath = entry.path, let keys = keysFromStringsAtURL(entry) else {
            continue
        }
        print("Processing \(filePath)...", separator: "", terminator: "")
        var unusedKeys = [String]()
        for k in keys {
            if !isUsedKey(k, atSearchPath: projectPath) {
                unusedKeys.append(k)
            }
        }
        if unusedKeys.count > 0 {
            print("FAIL!!!")
            print("\nUnused keys:")
            for k in unusedKeys {
                print("- \(k)")
            }
            print("")
        } else {
            print("OK")
        }
    }
}
