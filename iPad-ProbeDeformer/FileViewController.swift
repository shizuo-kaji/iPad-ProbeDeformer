//
//  FileViewController.swift
//  iPad-ProbeDeformer
//
//  Created by Shizuo KAJI on 08/12/2017.
//  Copyright © 2017 mcg-q. All rights reserved.
//

import UIKit

protocol FileViewControllerDelegate: AnyObject {
    func loadCSV(_ sender: Any)
}

class FileViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - Properties
    weak var delegate: FileViewControllerDelegate?
    var selectedPath: String = ""
    private var csvPaths: [String] = []
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    // MARK: - Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupPickerView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPickerView()
    }
    
    private func setupPickerView() {
        // This will be called after view is loaded
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pickerView = pickerView {
            pickerView.center = view.center
            pickerView.delegate = self
            pickerView.dataSource = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    @IBAction func close(_ sender: Any) {
        view.removeFromSuperview()
    }
    
    func load() {
        DispatchQueue.main.async {
            self.loadPaths()
        }
    }
    
    func loadPaths() {
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let dir = paths.first!
        var csvFilesPaths: [String] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: dir)
            for path in contents {
                let fullPath = (dir as NSString).appendingPathComponent(path)
                do {
                    let attrs = try fileManager.attributesOfItem(atPath: fullPath)
                    if let fileType = attrs[.type] as? FileAttributeType,
                       fileType == .typeRegular && path.hasSuffix(".csv") {
                        if !csvFilesPaths.contains(path) {
                            csvFilesPaths.append(path)
                        }
                    }
                } catch {
                    print("Error getting file attributes: \\(error)")
                }
            }
        } catch {
            print("Error reading directory contents: \\(error)")
        }
        
        if csvFilesPaths.isEmpty {
            csvFilesPaths.append("dummy")
        }
        
        csvPaths = csvFilesPaths
        pickerView.reloadAllComponents()
        pickerView.selectRow(0, inComponent: 0, animated: false)
        selectedPath = csvPaths[0]
        print("Dir: \\(dir)")
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return csvPaths.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return (csvPaths[row] as NSString).lastPathComponent
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let index0 = pickerView.selectedRow(inComponent: 0)
        selectedPath = csvPaths[index0]
    }
}