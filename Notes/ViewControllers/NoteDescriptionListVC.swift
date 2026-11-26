//
//  NoteDescriptionListVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

class NoteDescriptionListVC: UIViewController, UITableViewDelegate, UITableViewDataSource{


    //MARK:- OBJECTS & OUTLETS

    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblNavigationBarTitle: UILabel!
    @IBOutlet weak var tblViewNoteDescription: UITableView!
    @IBOutlet weak var navigationBarView1: UIView!
    @IBOutlet weak var navigationBarView2: UIView!

    var dictSelectedNote = [String : Any]()



    //MARK:- VIEW LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async { [self] in
            self.tblViewNoteDescription.estimatedRowHeight = 125.0
            self.tblViewNoteDescription.rowHeight = UITableView.automaticDimension
            
            
            let defaults = UserDefaults.standard
            
            let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
            
            print("selected ColorIndex")
            print(colorIndex)
            //self.updateColor(view: navigationBarView1, index: colorIndex)
        }
       
        
    }

    override func viewWillAppear(_ animated: Bool) {
        tblViewNoteDescription.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
        invalidateComponents()
    }
    override func viewDidAppear(_ animated: Bool) {
        let indicator = Indicator()
        indicator.showProgressView(self.view)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.resizeImageInHTMLContent(editorHTMLContent: self.dictSelectedNote["Description"] as! String) { updatedContent in
                if let updatedContent = updatedContent {
                    // Use updatedContent here (e.g., display it in a UITextView)
                    print("Updated HTML Content: \(updatedContent)")
                    DispatchQueue.main.async { [self] in
                        self.dictSelectedNote["Description"] = updatedContent
                        self.tblViewNoteDescription.reloadData()
                        indicator.hideProgressView()
                        tblViewNoteDescription.isHidden = false
                        //tableView.reloadData()
                        
                    }
                }else{
                    DispatchQueue.main.async { [self] in
                        self.tblViewNoteDescription.reloadData()
                        indicator.hideProgressView()
                        tblViewNoteDescription.isHidden = false
                        //tableView.reloadData()
                        
                    }
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func invalidateComponents() {
        
        let defaults = UserDefaults.standard
        
        let colorIndex = defaults.integer(forKey: MYTHEMECOLORINDEX)
        
        print("selected ColorIndex")
        print(colorIndex)
        
        if colorIndex != 0 {
            
          //  updateColor(view: navigationBarView1, index: colorIndex)
            //updateTableView()
            
        }
        
        let fontIndex = defaults.integer(forKey: MYTHEMEFONTINDEX)
        
        print("selected FontIndex")
        print(fontIndex)
        
        if fontIndex != 0 {
            
            updateFont(fontIndex: fontIndex)
            
        }
    }
    
    func updateColor(view: UIView, index: Int) {
        
        var mythemecolor1 = mythemeColor0_1
        var mythemecolor2 = mythemeColor0_2
        
        switch index {
        case 1:
            mythemecolor1 = mythemeColor1_1
            mythemecolor2 = mythemeColor1_2
        case 2:
            mythemecolor1 = mythemeColor2_1
            mythemecolor2 = mythemeColor2_2
        case 3:
            mythemecolor1 = mythemeColor3_1
            mythemecolor2 = mythemeColor3_2
        case 4:
            mythemecolor1 = mythemeColor4_1
            mythemecolor2 = mythemeColor4_2
        case 5:
            mythemecolor1 = mythemeColor5_1
            mythemecolor2 = mythemeColor5_2
        default:
            mythemecolor1 = mythemeColor0_1
            mythemecolor2 = mythemeColor0_2
        }
        
        /*
        var firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(0.0)
        if index == 5 {
            firstColor = UIColor(rgb: mythemecolor1).withAlphaComponent(1.0)
        }
        let secondColor = UIColor(rgb: mythemecolor2).withAlphaComponent(1.0)
        */
        
        let layer = view.layer as! CAGradientLayer
        layer.colors = [mythemecolor1,mythemecolor2].map({$0.cgColor})
        layer.startPoint = CGPoint(x: 0, y: 1)
        layer.endPoint = CGPoint(x: 1, y: 0.0)
        
    }
    
    func updateFont(fontIndex: Int) {
        
        print("font change")
        print(fontIndex)
        
        let fontsize: CGFloat = 17
        
        switch fontIndex {
        case 1:
            lblNavigationBarTitle.font = UIFont(name: "SanFranciscoDisplay-Regular", size: fontsize)
        case 2:
            lblNavigationBarTitle.font = UIFont(name: "Comic Sans MS", size: fontsize)
        case 3:
            lblNavigationBarTitle.font = UIFont(name: "Helvetica", size: fontsize)
        case 4:
            lblNavigationBarTitle.font = UIFont(name: "Times New Roman", size: fontsize)
        case 5:
            lblNavigationBarTitle.font = UIFont(name: "Bodoni 72 Book", size: fontsize)
        default:
            lblNavigationBarTitle.font = ApplazAppearance.font(fontsize, weight: .medium)
        }
        
        
        
    }
    
    //MARK:- UITABLE VIEW DELEGATE & DATA SOURCE METHODS

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return IS_IPAD ? 35.0 : 15.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return IS_IPAD ? 35.0 : 15.0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: IS_IPAD ? 35.0 : 15.0))
        footerView.backgroundColor = .clear
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = self.tblViewNoteDescription.dequeueReusableCell(withIdentifier: "NoteDescriptionTBLViewCell") as! NoteDescriptionTBLViewCell
        cell.lblNoteTitle.text = "Title:  \(String(describing: self.dictSelectedNote["Title"] as? String ?? ""))"
        cell.lblNoteDescription.attributedText = (self.dictSelectedNote["Description"] as! String).setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: "HelveticaNeue-Medium")
        //let imageSize = CGSize(width: cell.lblNoteDescription.frame.width - 10, height: cell.lblNoteDescription.frame.width - 10)
//        resizeImageInHTMLContent(editorHTMLContent: self.dictSelectedNote["Description"] as! String,imageSize:imageSize) { updatedContent in
//            if let updatedContent = updatedContent {
//                // Use updatedContent here (e.g., display it in a UITextView)
//                print("Updated HTML Content: \(updatedContent)")
//                DispatchQueue.main.async {
//                    cell.lblNoteTitle.text = self.dictSelectedNote["Title"] as? String
//                    cell.lblNoteDescription.attributedText = (updatedContent as String).setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: "HelveticaNeue-Medium")
//                    //tableView.reloadData()
//                    
//                }
//            } else {
//                print("Failed to resize image or no image found.")
//                DispatchQueue.main.async {
//                    cell.lblNoteTitle.text = self.dictSelectedNote["Title"] as? String
//                    cell.lblNoteDescription.attributedText = (self.dictSelectedNote["Description"] as! String).setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: "HelveticaNeue-Medium")
//                    tableView.reloadData()
//                }
//                
//            }
//        }
//        print("Attributed string note\(String(describing: stringFromHtml(string: self.dictSelectedNote["notedescription"] as! String)?.setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: cell.lblNoteTitle.font.fontName)))")
  
//        cell.lblNoteDescription.attributedText = stringFromHtml(string: self.dictSelectedNote["notedescription"] as! String)?.setAttributetext(fontsize: Double(cell.lblNoteDescription.font.pointSize), fontName: cell.lblNoteTitle.font.fontName)

        return cell
    }

    func resizeImageInHTMLContent(editorHTMLContent: String, completion: @escaping (String?) -> Void) {
        var imageURL: URL?
        
        // Find the image tag within the HTML content
        if let range = editorHTMLContent.range(of: "<img src=\"(.*?)\"", options: .regularExpression){
           let extractedImageURL = editorHTMLContent[range].replacingOccurrences(of: "<img src=\"", with: "").replacingOccurrences(of: "\"", with: "")
            // extractedImageURL contains the URL of the image
            imageURL = URL(string: extractedImageURL)
        }
        
        // Check for imageURL and proceed with resizing and replacement
        if let url = imageURL {
            let imageSize: CGSize = UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: 700, height: 700) : CGSize(width: 350, height: 350)
            
            // Load the image from the URL and resize it
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData){
                   //let resizedImage = image.resizeImage(to: imageSize) { // Implement your image resizing logic here
                    
                    // Convert the resized image back to Data or Base64 as needed
                    if let resizedImageData = image.jpegData(compressionQuality: 0.8) {
                        // Convert resizedImageData to Base64 or Data if required
                        
                        // Create a string with the modified HTML content (replace the old image tag with the resized one)
                        let resizedImageTag = "<img src=\"data:image/jpeg;base64,\(resizedImageData.base64EncodedString())\" width=\"\(imageSize.width)\" height=\"\(imageSize.height)\" alt=\"\">"
                        
                        let regexPattern = "<img[^>]+>"
                        if let regex = try? NSRegularExpression(pattern: regexPattern) {
                            let range = NSRange(location: 0, length: editorHTMLContent.utf16.count)
                            let modifiedString = regex.stringByReplacingMatches(in: editorHTMLContent, options: [], range: range, withTemplate: resizedImageTag)
                            print(modifiedString)
                            completion(modifiedString)
                            return
                        } else {
                            print("Regular expression pattern is invalid.")
                            completion(nil)
                            return
                        }
                    }
                }
                
                // If there's an issue during the process, return nil
                completion(nil)
            }
        } else {
            // If no image URL is found, return nil
            completion(nil)
        }
    }
    //MARK:- BUTTON'S ACTIONS

    @IBAction func btnBackPressed(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
