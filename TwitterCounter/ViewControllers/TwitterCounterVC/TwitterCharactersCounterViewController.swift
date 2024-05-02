//
//  TwitterCharactersCounterViewController.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 30/04/2024.
//

import UIKit
import TWTextEditorSDK
import OAuthSwift

class TwitterCharactersCounterViewController: UIViewController {
    
    @IBOutlet weak var twTextView: TWTextEditorView!
    @IBOutlet weak var typedCharactersLabel: CounterLabel!
    @IBOutlet weak var remainingCharactersLabel: CounterLabel!
    
    
    private var networkService: NetworkService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavBar()
        twTextView.viewDelegate = self
        hideKeyboardWhenTappedAround()
        self.networkService = URLSessionNetworkService()
    }
    
    
    func setUpNavBar(){
        //For title in navigation bar
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0.11, green: 0.129, blue: 0.122, alpha: 1)
        self.navigationItem.title = "Twitter character count"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 0.11, green: 0.129, blue: 0.122, alpha: 1),
                                                                        NSAttributedString.Key.font: UIFont.twFontMediumWithSize(size: 18)]
    }
    
    @IBAction func copyTextButtonAction(_ sender: Any) {
        self.twTextView.copyCurrentText()
    }
    
    @IBAction func clearTextButtonAction(_ sender: Any) {
        self.twTextView.clearText()
    }
    
    
    @IBAction func postTweetAction(_ sender: Any) {
        Task {
            await self.authorizeAndGetToken()
        }
    }
    
    private func authorizeAndGetToken() async {
        let bundelId = Bundle.main.bundleIdentifier!
        let authDomain = "api.twitter.com"
        let authorizationUrl = "https://\(authDomain)/oauth/authorize"
        let tokenURL = "https://\(authDomain)/oauth/token"
        let consumerKey =    "b8ja6swBKS7zxeZAgch5uJLJh"
        let redirectURL = "\(bundelId)://\(authDomain)/ios/\(bundelId)/callback"
        let consumerSecret = "6DbkZ0dYXVpHJU5nCSN0zCZXwGeUgYhuwjzaNa1paqlGKoAIDw"
        let scope = "tweet.read tweet.write"
        let state = generateRandomString(length: 30)
        let clientId = "OXAzUThlVUpZRlE5UGp3T0dGSWg6MTpjaQ"

        
        // Initialize OAuth2Swift with your Twitter app credentials
        let oauthswift = OAuth2Swift(
            consumerKey:    consumerKey,
            consumerSecret: consumerSecret,
            authorizeUrl:   authorizationUrl,
            accessTokenUrl: tokenURL,
            responseType:   "code"
        )
        
        
        guard let codeVerifier = generateCodeVerifier() else {return}
        guard let codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier) else {return}
        
         oauthswift.authorize(
            withCallbackURL: redirectURL,
            scope: scope,
            state:state,
            codeChallenge: codeChallenge,
            codeChallengeMethod: "S256",
            codeVerifier: codeVerifier) { result in
                switch result {
                case .success(let (credential, _, _)):
                    // Store the OAuth token
                    let oauthToken = credential.oauthToken
                    Task {
                        await self.postTweet(authToken: oauthToken)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        
    }
    
    
    private func postTweet(authToken: String) async {
        let postTweetPath = "2/tweets"
        let headers = ["Authorization": "Bearer \(authToken)"]
        
        Task {
            do {
                let result: Result<TweetResponse, NetworkError>  = try await networkService.performRequest(endPoint:postTweetPath,
                                                                                                           method: .post,
                                                                                                           header: headers)
                switch result {
                case .success(let tweet):
                    print("Tweet posted:", tweet.data.text)
                    
                case .failure(let error):
                    print("Failed to post tweet:", error.localizedDescription)
                }
            } catch {
                print("Error during network call:", error.localizedDescription)
            }
            
        }
    }
    
    private func generateRandomString(length: Int) -> String {
         let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
         return String((0..<length).map{ _ in letters.randomElement()! })
     }
}

extension TwitterCharactersCounterViewController: TWTextEditorViewDelegate {
  
    func textDidChange(_ textView: UITextView) {
        
        self.typedCharactersLabel.text = "\(self.twTextView.typedCharactersCount )/\(self.twTextView.maxCountOfCharacters)"
        self.remainingCharactersLabel.text = "\(self.twTextView.remainingCharactersCount)"
        
    }
}

