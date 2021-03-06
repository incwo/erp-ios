//
//  AccountCreationViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import Foundation
import UIKit
import WebKit


@objc
public protocol AccountCreationViewControllerDelegate: class {
    func accountCreationViewControllerDidCreateAccount(_ controller: AccountCreationViewController, email: String)
    func accountCreationViewControllerDidCancel(_ controller: AccountCreationViewController)
    func accountCreationViewControllerDidFail(_ controller: AccountCreationViewController, error: NSError)
}

/// A view controller which contains a WKWebView which shows the page to create a user account (= Sign up)
@objc
public class AccountCreationViewController: UIViewController {
    private weak var delegate: AccountCreationViewControllerDelegate!
    var webView: WKWebView {
        get {
            return view as! WKWebView
        }
    }
    
    @objc
    public init(delegate: AccountCreationViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func loadView() {
        view = WKWebView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        assert(delegate != nil, "The delegate must be set.")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        webView.navigationDelegate = self
        webView.load(FCLSession.signupRequest())
    }
    
    @objc
    func cancel() {
        delegate.accountCreationViewControllerDidCancel(self)
    }
}

extension AccountCreationViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let pageUrl = navigationAction.request.url,
            let components = URLComponents(url: pageUrl, resolvingAgainstBaseURL: false) else {
                decisionHandler(.cancel)
                return
        }
        
        // When the account is created, the page redirects to
        //   http://facilepos.app/signin?email=<email>
        if components.host == "facilepos.app" {
            // Since this is a false host, the webview will not be able to handle it
            decisionHandler(.cancel)
            
            if components.path == "/signin",
                let queryItems = components.queryItems,
                queryItems.count == 1,
                queryItems.first?.name == "email",
                let email = queryItems.first?.value {
                delegate.accountCreationViewControllerDidCreateAccount(self, email: email.removingPercentEncoding!)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate.accountCreationViewControllerDidFail(self, error: error as NSError)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate.accountCreationViewControllerDidFail(self, error: error as NSError)
    }
}
