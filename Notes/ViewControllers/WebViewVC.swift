//
//  WebViewVC.swift
//  Notes
//
//  Created by Sevenstar Infotech on 15/03/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import WebKit


class WebViewVC: UIViewController, WKNavigationDelegate{

    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var navigationBarView: UIView!
     var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var webViewContainer: UIView!
    
    
    //MARK:- VIEW LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBarView.backgroundColor = BLUE_COLOR
        
        webView = WKWebView()
        webView.navigationDelegate = self

        // Add WKWebView to webViewContainer
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(webView)
        
        // Set constraints to match the webViewContainer
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.webView.load(URLRequest(url: URL(string: "http://www.sevenstarinfotech.com/")!))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    //MARK:- BUTTON'S ACTIONS
    
    @IBAction func btnDonePressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK:- UIWEBVIEW DELEGATE METHOD
    
    // WKNavigationDelegate equivalent for webViewDidStartLoad
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webView.isHidden = true
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }

    // WKNavigationDelegate equivalent for webViewDidFinishLoad
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        webView.isHidden = false
    }

    // WKNavigationDelegate equivalent for didFailLoadWithError
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        webView.isHidden = false
    }
}
